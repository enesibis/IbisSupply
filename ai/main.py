"""
IbisSupply — AI Servisi
FastAPI · Port 8000
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from anomaly_model import analyze, compute_batch_risk_score, get_shelf_life, SHELF_LIFE_STANDARDS
from delay_model import predict_delay

app = FastAPI(
    title="IbisSupply AI Service",
    description="Soğuk zincir anomali tespiti ve risk skoru",
    version="1.0.0",
)


# ── Request / Response modelleri ─────────────────────────────────────────────

class AnomalyRequest(BaseModel):
    temperatures: list[float] = Field(..., description="Sıcaklık ölçümleri (°C)")
    category: str = Field(..., description="Ürün kategorisi: DAIRY, MEAT, FISH, FROZEN vb.")
    duration_hours: float = Field(..., gt=0, description="Sevkiyat süresi (saat)")
    humidity_readings: Optional[list[float]] = Field(None, description="Nem ölçümleri (%)")


class AnomalyResponse(BaseModel):
    is_anomaly: bool
    risk_level: str
    risk_score: float
    anomaly_type: Optional[str]
    recommended_action: str
    details: dict


class RiskScoreRequest(BaseModel):
    temperatures: list[float]
    category: str
    duration_hours: float
    expiry_days_remaining: int = Field(..., ge=0)
    quality_check_result: Optional[str] = Field(
        None,
        description="PASSED / FAILED / NEEDS_REVIEW"
    )


class RiskScoreResponse(BaseModel):
    risk_score: float
    risk_level: str
    breakdown: dict
    anomaly_details: dict


# ── Endpoint'ler ─────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok", "service": "IbisSupply AI"}


@app.post("/ai/analyze-anomaly", response_model=AnomalyResponse)
def analyze_anomaly(req: AnomalyRequest):
    """
    Sıcaklık zaman serisi için soğuk zincir anomali analizi yapar.
    Backend'den ShipmentEvent temperature kayıtları gönderilir.
    """
    if not req.temperatures:
        raise HTTPException(status_code=400, detail="temperatures boş olamaz")

    result = analyze(
        temperatures=req.temperatures,
        category=req.category,
        duration_hours=req.duration_hours,
        humidity_readings=req.humidity_readings,
    )

    return AnomalyResponse(
        is_anomaly=result.is_anomaly,
        risk_level=result.risk_level,
        risk_score=result.risk_score,
        anomaly_type=result.anomaly_type,
        recommended_action=result.recommended_action,
        details=result.details,
    )


@app.post("/ai/risk-score", response_model=RiskScoreResponse)
def risk_score(req: RiskScoreRequest):
    """
    Bir batch için 0-100 risk skoru hesaplar.
    Anomali + kalite kontrol sonucu + son kullanma tarihi faktörleri dahil.
    """
    result = compute_batch_risk_score(
        temperatures=req.temperatures,
        category=req.category,
        duration_hours=req.duration_hours,
        expiry_days_remaining=req.expiry_days_remaining,
        quality_check_result=req.quality_check_result,
    )
    return RiskScoreResponse(**result)


@app.get("/ai/shelf-life/{category}")
def shelf_life(category: str):
    """
    Ürün kategorisi için raf ömrü standardını döner.
    Türk Gıda Kodeksi ve AB 853/2004 esas alınmıştır.
    """
    data = get_shelf_life(category)
    return {
        "category": category.upper(),
        **data,
    }


@app.get("/ai/shelf-life")
def all_shelf_life():
    """Tüm kategoriler için raf ömrü standartlarını döner."""
    return {cat: data for cat, data in SHELF_LIFE_STANDARDS.items() if cat != "DEFAULT"}


class DelayRequest(BaseModel):
    distance_km: float = Field(..., gt=0, description="Rota mesafesi (km)")
    planned_hours: float = Field(..., gt=0, description="Planlanan süre (saat)")
    vehicle_type: str = Field(..., description="TRUCK / REFRIGERATED_TRUCK / VAN")
    weather_condition: str = Field(..., description="CLEAR / CLOUDY / RAIN / FOG / SNOW")
    traffic_level: str = Field(..., description="LOW / MEDIUM / HIGH")
    category: str = Field(..., description="Ürün kategorisi: DAIRY, MEAT, FISH vb.")
    has_temperature_anomaly: bool = Field(False, description="Sıcaklık anomalisi var mı")
    number_of_stops: int = Field(0, ge=0, description="Durak sayısı")


class DelayResponse(BaseModel):
    delay_predicted: bool
    delay_probability: float
    estimated_delay_hours: float
    delay_risk_level: str
    delay_reasons: list
    recommendation: str
    details: dict


@app.post("/ai/predict-delay", response_model=DelayResponse)
def predict_delay_endpoint(req: DelayRequest):
    """
    Sevkiyat gecikmesi tahmini yapar.
    Mesafe, araç tipi, hava durumu, trafik ve anomali durumu dikkate alınır.
    """
    result = predict_delay(
        distance_km=req.distance_km,
        planned_hours=req.planned_hours,
        vehicle_type=req.vehicle_type,
        weather_condition=req.weather_condition,
        traffic_level=req.traffic_level,
        category=req.category,
        has_temperature_anomaly=req.has_temperature_anomaly,
        number_of_stops=req.number_of_stops,
    )
    return DelayResponse(
        delay_predicted=result.delay_predicted,
        delay_probability=result.delay_probability,
        estimated_delay_hours=result.estimated_delay_hours,
        delay_risk_level=result.delay_risk_level,
        delay_reasons=result.delay_reasons,
        recommendation=result.recommendation,
        details=result.details,
    )


@app.get("/ai/demo-anomaly")
def demo_anomaly():
    """
    Demo için hazır anomali örneği — jüri sunumunda kullanılabilir.
    Süt ürünü, 8°C'ye çıkan anormal sıcaklık.
    """
    result = analyze(
        temperatures=[3.1, 3.4, 3.2, 7.8, 9.1, 10.5, 9.8, 8.2],
        category="DAIRY",
        duration_hours=8.0,
    )
    return {
        "scenario": "Süt sevkiyatı — soğuk zincir kırılması",
        "is_anomaly": result.is_anomaly,
        "risk_level": result.risk_level,
        "risk_score": result.risk_score,
        "anomaly_type": result.anomaly_type,
        "recommended_action": result.recommended_action,
        "details": result.details,
    }
