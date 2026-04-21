package com.ibissupply.backend.dto.request;

import com.ibissupply.backend.enums.ShipmentEventType;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ShipmentEventRequest {

    @NotNull
    private ShipmentEventType eventType;

    private String locationAddress;
    private Double latitude;
    private Double longitude;
    private Double temperature;
    private Double humidity;
    private String notes;
}
