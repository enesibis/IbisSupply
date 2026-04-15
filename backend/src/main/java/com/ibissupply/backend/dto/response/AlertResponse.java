package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.Alert;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class AlertResponse {
    private UUID id;
    private String type;
    private String severity;
    private String message;
    private boolean resolved;
    private String batchCode;
    private String shipmentCode;
    private LocalDateTime createdAt;

    public static AlertResponse from(Alert a) {
        return AlertResponse.builder()
                .id(a.getId())
                .type(a.getType())
                .severity(a.getSeverity())
                .message(a.getMessage())
                .resolved(a.isResolved())
                .batchCode(a.getBatch() != null ? a.getBatch().getBatchCode() : null)
                .shipmentCode(a.getShipment() != null ? a.getShipment().getShipmentCode() : null)
                .createdAt(a.getCreatedAt())
                .build();
    }
}
