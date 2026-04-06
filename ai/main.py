"""
IbisSupply — AI Servisi
FastAPI · Port 8000
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from anomaly_model import analyze, compute_batch_risk_score

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
