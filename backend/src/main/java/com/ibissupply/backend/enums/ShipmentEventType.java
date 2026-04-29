package com.ibissupply.backend.enums;

public enum ShipmentEventType {
    CREATED,
    DEPARTED,
    CHECKPOINT,
    TEMP_LOG,
    TEMPERATURE_LOG,  // eski demo verisi uyumluluğu için
    DELIVERED,
    DELAYED,
    INCIDENT
}
