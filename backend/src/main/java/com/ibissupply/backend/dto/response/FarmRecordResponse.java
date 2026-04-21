package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.FarmRecord;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class FarmRecordResponse {

    private UUID id;

    private UUID batchId;
    private String batchCode;
    private String productName;

    private String producerName;

    private String fieldLocation;
    private LocalDate plantingDate;
    private LocalDate harvestDate;

    private String irrigationType;
    private Double totalIrrigationHours;

    private String pesticides;
    private String fertilizers;

    private String notes;
    private String blockchainTxHash;
    private LocalDateTime createdAt;

    public static FarmRecordResponse from(FarmRecord r) {
        return FarmRecordResponse.builder()
                .id(r.getId())
                .batchId(r.getBatch().getId())
                .batchCode(r.getBatch().getBatchCode())
                .productName(r.getBatch().getProduct() != null ? r.getBatch().getProduct().getName() : "")
                .producerName(r.getProducer().getFullName())
                .fieldLocation(r.getFieldLocation())
                .plantingDate(r.getPlantingDate())
                .harvestDate(r.getHarvestDate())
                .irrigationType(r.getIrrigationType())
                .totalIrrigationHours(r.getTotalIrrigationHours())
                .pesticides(r.getPesticides())
                .fertilizers(r.getFertilizers())
                .notes(r.getNotes())
                .blockchainTxHash(r.getBlockchainTxHash())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
