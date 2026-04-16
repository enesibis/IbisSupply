"""
IbisSupply — Gecikme Tahmini Modeli
Sevkiyat gecikmesini tahmin eder: RandomForest (sınıflandırma + regresyon)
Sentetik verilerle eğitilir, delay_model.pkl olarak kaydedilir.
"""

import numpy as np
import pandas as pd
import joblib
import os
from dataclasses import dataclass
from typing import Optional

DELAY_MODEL_PATH = os.path.join(os.path.dirname(__file__), "delay_model.pkl")

# Araç türü katsayısı (güvenilirlik: düşük = daha az gecikme riski)
VEHICLE_DELAY_FACTOR = {
    "REFRIGERATED_TRUCK": 0.8,   # özel araç, daha planlı
    "TRUCK": 1.0,
    "VAN": 1.1,
    "DEFAULT": 1.0,
}

# Hava durumu katsayısı
WEATHER_DELAY_FACTOR = {
    "CLEAR": 0.0,
    "CLOUDY": 0.1,
    "RAIN": 0.3,
    "FOG": 0.4,
    "SNOW": 0.7,
    "DEFAULT": 0.1,
}

# Trafik katsayısı
TRAFFIC_DELAY_FACTOR = {
    "LOW": 0.0,
    "MEDIUM": 0.3,
    "HIGH": 0.7,
    "DEFAULT": 0.2,
}

# Ürün kategorisi bozulabilirlik skoru (0-1, 1 = çok hassas)
CATEGORY_PERISHABILITY = {
    "FISH":      1.0,
    "MEAT":      0.9,
    "DAIRY":     0.8,
    "FROZEN":    0.7,
    "VEGETABLE": 0.6,
    "FRUIT":     0.6,
    "BAKERY":    0.4,
    "DRY_GOODS": 0.1,
    "DEFAULT":   0.5,
}


@dataclass
class DelayResult:
    delay_predicted: bool
    delay_probability: float   # 0-1
    estimated_delay_hours: float
    delay_risk_level: str      # LOW / MEDIUM / HIGH / CRITICAL
    delay_reasons: list
    recommendation: str
    details: dict


def _perishability(category: str) -> float:
    return CATEGORY_PERISHABILITY.get(category.upper(), CATEGORY_PERISHABILITY["DEFAULT"])


def _delay_risk_level(prob: float) -> str:
    if prob >= 0.75:
        return "CRITICAL"
    elif prob >= 0.50:
        return "HIGH"
    elif prob >= 0.25:
        return "MEDIUM"
    return "LOW"


# ── Sentetik eğitim verisi ───────────────────────────────────────────────────
def _generate_delay_training_data(n: int = 800) -> pd.DataFrame:
    rng = np.random.default_rng(99)
    records = []

    vehicles = list(VEHICLE_DELAY_FACTOR.keys())[:-1]
    weathers = list(WEATHER_DELAY_FACTOR.keys())[:-1]
    traffics = list(TRAFFIC_DELAY_FACTOR.keys())[:-1]
    categories = list(CATEGORY_PERISHABILITY.keys())[:-1]

    for _ in range(n):
        distance_km     = float(rng.uniform(50, 2000))
        planned_hours   = distance_km / rng.uniform(50, 80)   # 50-80 km/h ortalama
        vehicle         = rng.choice(vehicles)
        weather         = rng.choice(weathers)
        traffic         = rng.choice(traffics)
        category        = rng.choice(categories)
        has_anomaly     = int(rng.random() < 0.25)
        n_stops         = int(rng.uniform(0, 5))

        v_f = VEHICLE_DELAY_FACTOR[vehicle]
        w_f = WEATHER_DELAY_FACTOR[weather]
        t_f = TRAFFIC_DELAY_FACTOR[traffic]
        p   = _perishability(category)

        # Gecikme olasılığı hesabı (kural tabanlı)
        base_prob = 0.1 + w_f * 0.35 + t_f * 0.35 + has_anomaly * 0.15 + (n_stops * 0.02)
        base_prob = base_prob * v_f
        base_prob = float(np.clip(base_prob + rng.normal(0, 0.05), 0.0, 1.0))

        is_delayed = int(base_prob > 0.45)
        delay_hours = 0.0
        if is_delayed:
            delay_hours = float(np.clip(
                rng.normal(planned_hours * 0.3 * base_prob, 1.5), 0.5, planned_hours * 0.8
            ))

        records.append({
            "distance_km":      distance_km,
            "planned_hours":    planned_hours,
            "vehicle_factor":   v_f,
            "weather_factor":   w_f,
            "traffic_factor":   t_f,
            "perishability":    p,
            "has_anomaly":      has_anomaly,
            "n_stops":          n_stops,
            "is_delayed":       is_delayed,
            "delay_hours":      delay_hours,
        })

    return pd.DataFrame(records)


FEATURE_COLS = [
    "distance_km", "planned_hours", "vehicle_factor",
    "weather_factor", "traffic_factor", "perishability",
    "has_anomaly", "n_stops",
]


def _train_and_save():
    from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
    from sklearn.preprocessing import StandardScaler
    from sklearn.pipeline import Pipeline

    df = _generate_delay_training_data(800)

    X = df[FEATURE_COLS]
    y_cls = df["is_delayed"]
    y_reg = df["delay_hours"]

    clf_pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", RandomForestClassifier(n_estimators=100, random_state=99, class_weight="balanced")),
    ])
    clf_pipeline.fit(X, y_cls)

    reg_pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("reg", RandomForestRegressor(n_estimators=100, random_state=99)),
    ])
    reg_pipeline.fit(X, y_reg)

    joblib.dump({"clf": clf_pipeline, "reg": reg_pipeline}, DELAY_MODEL_PATH)
    print(f"Gecikme modeli kaydedildi: {DELAY_MODEL_PATH}")
    return clf_pipeline, reg_pipeline


def _load_delay_model():
    if not os.path.exists(DELAY_MODEL_PATH):
        _train_and_save()
    bundle = joblib.load(DELAY_MODEL_PATH)
    return bundle["clf"], bundle["reg"]


# ── Ana tahmin fonksiyonu ─────────────────────────────────────────────────────
def predict_delay(
    distance_km: float,
    planned_hours: float,
    vehicle_type: str,
    weather_condition: str,
    traffic_level: str,
    category: str,
    has_temperature_anomaly: bool = False,
    number_of_stops: int = 0,
) -> DelayResult:

    clf, reg = _load_delay_model()

    v_f = VEHICLE_DELAY_FACTOR.get(vehicle_type.upper(), VEHICLE_DELAY_FACTOR["DEFAULT"])
    w_f = WEATHER_DELAY_FACTOR.get(weather_condition.upper(), WEATHER_DELAY_FACTOR["DEFAULT"])
    t_f = TRAFFIC_DELAY_FACTOR.get(traffic_level.upper(), TRAFFIC_DELAY_FACTOR["DEFAULT"])
    p   = _perishability(category)

    row = pd.DataFrame([{
        "distance_km":      distance_km,
        "planned_hours":    planned_hours,
        "vehicle_factor":   v_f,
        "weather_factor":   w_f,
        "traffic_factor":   t_f,
        "perishability":    p,
        "has_anomaly":      int(has_temperature_anomaly),
        "n_stops":          number_of_stops,
    }])

    delay_prob  = float(clf.predict_proba(row)[0][1])
    delay_hours = max(0.0, float(reg.predict(row)[0]))

    delay_predicted = delay_prob >= 0.45
    risk_level = _delay_risk_level(delay_prob)

    # Gecikme sebepleri
    reasons = []
    if w_f >= 0.3:
        reasons.append(f"Hava koşulları ({weather_condition.lower()})")
    if t_f >= 0.3:
        reasons.append(f"Yoğun trafik ({traffic_level.lower()})")
    if has_temperature_anomaly:
        reasons.append("Sıcaklık anomalisi — araç beklemesi gerekebilir")
    if number_of_stops >= 3:
        reasons.append(f"Çok sayıda durak ({number_of_stops})")
    if distance_km > 1000:
        reasons.append(f"Uzun mesafe ({distance_km:.0f} km)")
    if not reasons and delay_predicted:
        reasons.append("Genel rota riski")

    recommendation = _delay_recommendation(risk_level, reasons, p)

    return DelayResult(
        delay_predicted=delay_predicted,
        delay_probability=round(delay_prob, 3),
        estimated_delay_hours=round(delay_hours, 1),
        delay_risk_level=risk_level,
        delay_reasons=reasons,
        recommendation=recommendation,
        details={
            "distance_km": distance_km,
            "planned_hours": round(planned_hours, 1),
            "weather_factor": w_f,
            "traffic_factor": t_f,
            "vehicle_factor": v_f,
            "category_perishability": p,
        },
    )


def _delay_recommendation(risk_level: str, reasons: list, perishability: float) -> str:
    if risk_level == "CRITICAL":
        if perishability >= 0.8:
            return "ACİL: Gecikme riski kritik, bozulabilir ürün. Alternatif rota veya yedek araç planlayın."
        return "Gecikme riski kritik. Alternatif güzergah veya acil lojistik planlayın."
    elif risk_level == "HIGH":
        if perishability >= 0.7:
            return "Yüksek gecikme riski — hassas ürün. Yedek soğuk zincir noktası rezerve edin."
        return "Yüksek gecikme riski. Müşteriyi önceden bilgilendirin ve güzergahı gözden geçirin."
    elif risk_level == "MEDIUM":
        return "Orta gecikme riski. Sürücüyü bilgilendirin, kontrol noktalarını sıklaştırın."
    return "Düşük gecikme riski. Standart takip prosedürüne devam edin."


if __name__ == "__main__":
    _train_and_save()
    result = predict_delay(
        distance_km=850,
        planned_hours=14,
        vehicle_type="REFRIGERATED_TRUCK",
        weather_condition="RAIN",
        traffic_level="HIGH",
        category="DAIRY",
        has_temperature_anomaly=True,
        number_of_stops=2,
    )
    print(f"Gecikme tahmini: {result.delay_predicted}")
    print(f"Olasılık: {result.delay_probability:.1%}")
    print(f"Tahmini gecikme: {result.estimated_delay_hours} saat")
    print(f"Risk: {result.delay_risk_level}")
    print(f"Sebepler: {result.delay_reasons}")
