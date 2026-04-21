package com.ibissupply.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class BatchRequest {
    @NotNull
    private UUID productId;
    @NotNull @Positive
    private Double quantity;
    @NotBlank
    private String unit;
    @NotNull
    private LocalDate productionDate;
    private LocalDate expiryDate;
    private String originLocation;
}
