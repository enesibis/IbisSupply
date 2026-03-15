package com.ibissupply.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class ShipmentRequest {

    @NotNull
    private UUID batchId;

    @NotBlank
    private String fromLocation;

    @NotBlank
    private String toLocation;

    private String vehiclePlate;

    private String notes;
}
