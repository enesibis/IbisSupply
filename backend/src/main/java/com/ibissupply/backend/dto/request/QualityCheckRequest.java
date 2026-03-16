package com.ibissupply.backend.dto.request;

import com.ibissupply.backend.enums.CheckResult;
import lombok.Data;

import java.util.UUID;

@Data
public class QualityCheckRequest {
    private UUID batchId;
    private CheckResult result;
    private Double temperature;
    private Double humidity;
    private Boolean contaminationDetected;
    private String notes;
}
