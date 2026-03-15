package com.ibissupply.backend.dto.request;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class BatchRequest {
    private UUID productId;
    private Double quantity;
    private String unit;
    private LocalDate productionDate;
    private LocalDate expiryDate;
    private String originLocation;
}
