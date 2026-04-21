package com.ibissupply.backend.dto.request;

import com.ibissupply.backend.enums.CheckResult;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class QualityCheckRequest {
    @NotNull
    private UUID batchId;
    @NotNull
    private CheckResult result;
    private Double temperature;
    private Double humidity;
    private Boolean contaminationDetected;
    private String notes;
}
