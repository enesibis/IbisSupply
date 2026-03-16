package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.QualityCheck;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class QualityCheckResponse {
    private UUID id;
    private UUID batchId;
    private String batchCode;
    private String productName;
    private String inspectorName;
    private String result;
    private Double temperature;
    private Double humidity;
    private Boolean contaminationDetected;
    private String notes;
    private LocalDateTime checkedAt;

    public static QualityCheckResponse from(QualityCheck q) {
        return QualityCheckResponse.builder()
                .id(q.getId())
                .batchId(q.getBatch().getId())
                .batchCode(q.getBatch().getBatchCode())
                .productName(q.getBatch().getProduct() != null ? q.getBatch().getProduct().getName() : "")
                .inspectorName(q.getInspector() != null ? q.getInspector().getFullName() : "")
                .result(q.getResult().name())
                .temperature(q.getTemperature())
                .humidity(q.getHumidity())
                .contaminationDetected(q.getContaminationDetected())
                .notes(q.getNotes())
                .checkedAt(q.getCheckedAt())
                .build();
    }
}
