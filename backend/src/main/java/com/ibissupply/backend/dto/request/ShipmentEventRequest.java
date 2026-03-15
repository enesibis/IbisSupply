package com.ibissupply.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ShipmentEventRequest {

    @NotBlank
    private String eventType; // DEPARTED, CHECKPOINT, TEMPERATURE_LOG, DELIVERED, INCIDENT

    private String locationAddress;
    private Double latitude;
    private Double longitude;
    private Double temperature;
    private Double humidity;
    private String notes;
}
