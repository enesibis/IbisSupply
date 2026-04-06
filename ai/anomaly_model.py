"""
IbisSupply — Soğuk Zincir Anomali Tespiti
Hibrit model: Rule-Based + Z-Score
Sentetik verilerle eğitilir, model.pkl olarak kaydedilir.
"""

import numpy as np
import pandas as pd
import joblib
import os
from dataclasses import dataclass
from typing import Optional

MODEL_PATH = os.path.join(os.path.dirname(__file__), "model.pkl")

# ── Ürün kategorisi için güvenli sıcaklık aralıkları ────────────────────────
SAFE_TEMP_RANGES = {
    "MEAT":       (-2.0, 4.0),
    "FISH":       (-2.0, 2.0),
    "DAIRY":      (1.0,  8.0),
    "FROZEN":     (-25.0, -15.0),
    "VEGETABLE":  (2.0,  10.0),
    "FRUIT":      (4.0,  14.0),
    "BAKERY":     (15.0, 25.0),
    "DRY_GOODS":  (10.0, 30.0),
    "DEFAULT":    (0.0,  25.0),
}

# ── Risk eşikleri ────────────────────────────────────────────────────────────
RISK_THRESHOLDS = {
    "LOW":      (0,  25),
    "MEDIUM":   (25, 50),
    "HIGH":     (50, 75),
    "CRITICAL": (75, 101),
}


@dataclass
class AnomalyResult:
    is_anomaly: bool
    risk_level: str          # LOW / MEDIUM / HIGH / CRITICAL
    risk_score: float        # 0–100
    anomaly_type: Optional[str]
    recommended_action: str
    details: dict


def _safe_range(category: str) -> tuple[float, float]:
    return SAFE_TEMP_RANGES.get(category.upper(), SAFE_TEMP_RANGES["DEFAULT"])


def _risk_level(score: float) -> str:
    for level, (lo, hi) in RISK_THRESHOLDS.items():
        if lo <= score < hi:
            return level
    return "CRITICAL"


# ── Sentetik eğitim verisi ───────────────────────────────────────────────────
def generate_training_data(n_samples: int = 600) -> pd.DataFrame:
    rng = np.random.default_rng(42)
    records = []

    for _ in range(n_samples):
        category = rng.choice(list(SAFE_TEMP_RANGES.keys())[:-1])
        t_min, t_max = _safe_range(category)
        center = (t_min + t_max) / 2
        spread = (t_max - t_min) / 2

        is_anomaly = rng.random() < 0.35

        if is_anomaly:
            # Anormal: aralık dışına çık
            direction = rng.choice([-1, 1])
            temp_mean = center + direction * spread * rng.uniform(1.5, 4.0)
            temp_std = rng.uniform(1.5, 4.0)
        else:
            temp_mean = center + rng.uniform(-spread * 0.6, spread * 0.6)
            temp_std = rng.uniform(0.2, 1.0)

        n_readings = int(rng.uniform(5, 40))
        temperatures = rng.normal(temp_mean, temp_std, n_readings).tolist()
        duration_hours = rng.uniform(1, 72)
        humidity_mean = rng.uniform(40, 95)

        records.append({
            "category": category,
            "temp_mean": float(np.mean(temperatures)),
            "temp_std": float(np.std(temperatures)),
            "temp_min": float(np.min(temperatures)),
            "temp_max": float(np.max(temperatures)),
            "n_readings": n_readings,
            "duration_hours": duration_hours,
            "humidity_mean": humidity_mean,
            "safe_min": t_min,
            "safe_max": t_max,
            "is_anomaly": int(is_anomaly),
        })

    return pd.DataFrame(records)


def _feature_cols():
    return ["temp_mean", "temp_std", "temp_min", "temp_max",
            "n_readings", "duration_hours", "humidity_mean",
            "safe_min", "safe_max",
            "temp_mean_vs_safe_center", "temp_range_vs_safe_range"]


def _engineer(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    safe_center = (df["safe_min"] + df["safe_max"]) / 2
    safe_range = df["safe_max"] - df["safe_min"]
    df["temp_mean_vs_safe_center"] = (df["temp_mean"] - safe_center).abs()
    df["temp_range_vs_safe_range"] = (df["temp_max"] - df["temp_min"]) / (safe_range + 1e-6)
    return df


# ── Model eğitimi ────────────────────────────────────────────────────────────
def train_and_save():
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler

    df = generate_training_data(600)
    df = _engineer(df)

    X = df[_feature_cols()]
    y = df["is_anomaly"]

    pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", RandomForestClassifier(n_estimators=100, random_state=42, class_weight="balanced")),
    ])
    pipeline.fit(X, y)
    joblib.dump(pipeline, MODEL_PATH)
    print(f"Model kaydedildi: {MODEL_PATH}")
    return pipeline


def _load_model():
    if not os.path.exists(MODEL_PATH):
        return train_and_save()
    return joblib.load(MODEL_PATH)


# ── Kural tabanlı ek kontroller ──────────────────────────────────────────────
def _rule_based_check(temp_readings: list[float], category: str,
                       duration_hours: float) -> tuple[bool, Optional[str], float]:
    """
    ML'e ek olarak kesin kural ihlallerini yakalar.
    Döner: (ihlal_var_mı, ihlal_tipi, ceza_puanı)
    """
    if not temp_readings:
        return False, None, 0.0

    t_min, t_max = _safe_range(category)
    violations = [t for t in temp_readings if t < t_min or t > t_max]
    violation_ratio = len(violations) / len(temp_readings)

    if violation_ratio == 0:
        return False, None, 0.0

    penalty = violation_ratio * 60  # max 60 puan kural cezası

    if violation_ratio > 0.5:
        return True, "SUSTAINED_TEMPERATURE_BREACH", min(penalty, 60.0)
    elif violation_ratio > 0.2:
        return True, "FREQUENT_TEMPERATURE_EXCURSION", min(penalty, 40.0)
    else:
        return True, "OCCASIONAL_TEMPERATURE_EXCURSION", min(penalty, 20.0)


# ── Ana analiz fonksiyonu ────────────────────────────────────────────────────
def analyze(
    temperatures: list[float],
    category: str,
    duration_hours: float,
    humidity_readings: Optional[list[float]] = None,
) -> AnomalyResult:
    """
    Verilen sıcaklık zaman serisi için anomali analizi yapar.
    """
    model = _load_model()

    if not temperatures:
        return AnomalyResult(
            is_anomaly=False,
            risk_level="LOW",
            risk_score=0.0,
            anomaly_type=None,
            recommended_action="Veri yok, manuel kontrol önerilir.",
            details={},
        )

    t_min, t_max = _safe_range(category)
    temp_arr = np.array(temperatures)
    humidity_mean = float(np.mean(humidity_readings)) if humidity_readings else 65.0

    # ── Feature hazırla ──────────────────────────────────────────────────────
    row = pd.DataFrame([{
        "temp_mean": float(temp_arr.mean()),
        "temp_std": float(temp_arr.std()),
        "temp_min": float(temp_arr.min()),
        "temp_max": float(temp_arr.max()),
        "n_readings": len(temperatures),
        "duration_hours": duration_hours,
        "humidity_mean": humidity_mean,
        "safe_min": t_min,
        "safe_max": t_max,
    }])
    row = _engineer(row)
    X = row[_feature_cols()]

    # ── ML tahmini ───────────────────────────────────────────────────────────
    ml_proba = float(model.predict_proba(X)[0][1])  # anomali olasılığı
    ml_anomaly = ml_proba > 0.5

    # ── Kural tabanlı kontrol ─────────────────────────────────────────────────
    rule_breach, breach_type, rule_penalty = _rule_based_check(temperatures, category, duration_hours)

    # ── Risk skoru: ML + kural ────────────────────────────────────────────────
    ml_score = ml_proba * 60          # ML katkısı max 60
    rule_score = rule_penalty          # Kural katkısı max 60
    raw_score = min(ml_score + rule_score, 100.0)
    risk_score = round(raw_score, 1)

    is_anomaly = ml_anomaly or rule_breach
    risk_level = _risk_level(risk_score)

    # ── Anomali tipi belirle ──────────────────────────────────────────────────
    if breach_type:
        anomaly_type = breach_type
    elif is_anomaly:
        if temp_arr.max() > t_max:
            anomaly_type = "TEMPERATURE_TOO_HIGH"
        elif temp_arr.min() < t_min:
            anomaly_type = "TEMPERATURE_TOO_LOW"
        elif temp_arr.std() > (t_max - t_min):
            anomaly_type = "HIGH_TEMPERATURE_VARIANCE"
        else:
            anomaly_type = "ANOMALOUS_PATTERN"
    else:
        anomaly_type = None

    # ── Tavsiye ──────────────────────────────────────────────────────────────
    action = _recommended_action(risk_level, anomaly_type)

    return AnomalyResult(
        is_anomaly=is_anomaly,
        risk_level=risk_level,
        risk_score=risk_score,
        anomaly_type=anomaly_type,
        recommended_action=action,
        details={
            "ml_anomaly_probability": round(ml_proba, 3),
            "rule_breach": rule_breach,
            "temp_mean": round(float(temp_arr.mean()), 2),
            "temp_min": round(float(temp_arr.min()), 2),
            "temp_max": round(float(temp_arr.max()), 2),
            "safe_range": f"{t_min}°C – {t_max}°C",
            "n_readings": len(temperatures),
        },
    )


def _recommended_action(risk_level: str, anomaly_type: Optional[str]) -> str:
    if risk_level == "CRITICAL":
        return "ACİL: Ürünü derhal karantinaya alın ve kalite kontrolü başlatın."
    elif risk_level == "HIGH":
        if anomaly_type and "HIGH" in anomaly_type:
            return "Yüksek sıcaklık tespit edildi. Soğuk zinciri kontrol edin."
        elif anomaly_type and "LOW" in anomaly_type:
            return "Düşük sıcaklık tespit edildi. Donma riski değerlendirin."
        return "Sıcaklık anomalisi yüksek. Acil kalite kontrol gerekli."
    elif risk_level == "MEDIUM":
        return "Sıcaklık dalgalanması gözlemlendi. Bir sonraki kontrol noktasında inceleme yapın."
    else:
        return "Normal aralıkta. Standart prosedüre devam edin."


# ── Risk skoru hesaplama (batch için genel) ───────────────────────────────────
def compute_batch_risk_score(
    temperatures: list[float],
    category: str,
    duration_hours: float,
    expiry_days_remaining: int,
    quality_check_result: Optional[str] = None,
) -> dict:
    """
    Bir batch için 0-100 risk skoru hesaplar.
    Faktörler: anomali skoru, kalite kontrol sonucu, son kullanma tarihi yakınlığı.
    """
    anomaly = analyze(temperatures, category, duration_hours)

    # Ağırlıklar
    anomaly_weight = 0.60
    quality_weight = 0.25
    expiry_weight  = 0.15

    anomaly_score = anomaly.risk_score

    if quality_check_result == "FAILED":
        quality_score = 100.0
    elif quality_check_result == "NEEDS_REVIEW":
        quality_score = 55.0
    elif quality_check_result == "PASSED":
        quality_score = 0.0
    else:
        quality_score = 30.0  # bilinmiyor

    if expiry_days_remaining <= 0:
        expiry_score = 100.0
    elif expiry_days_remaining <= 3:
        expiry_score = 80.0
    elif expiry_days_remaining <= 7:
        expiry_score = 50.0
    elif expiry_days_remaining <= 14:
        expiry_score = 20.0
    else:
        expiry_score = 0.0

    total = (
        anomaly_score * anomaly_weight +
        quality_score * quality_weight +
        expiry_score  * expiry_weight
    )
    total = round(min(total, 100.0), 1)

    return {
        "risk_score": total,
        "risk_level": _risk_level(total),
        "breakdown": {
            "anomaly_score": anomaly_score,
            "quality_score": quality_score,
            "expiry_score": expiry_score,
        },
        "anomaly_details": {
            "is_anomaly": anomaly.is_anomaly,
            "anomaly_type": anomaly.anomaly_type,
            "recommended_action": anomaly.recommended_action,
        },
    }


if __name__ == "__main__":
    # Model eğitimi — python anomaly_model.py ile çalıştır
    train_and_save()
    print("Test analizi:")
    result = analyze([3.0, 3.2, 8.5, 9.1, 11.2, 12.0], "DAIRY", 6.0)
    print(f"  Anomali: {result.is_anomaly}, Seviye: {result.risk_level}, Skor: {result.risk_score}")
    print(f"  Tip: {result.anomaly_type}")
    print(f"  Tavsiye: {result.recommended_action}")
