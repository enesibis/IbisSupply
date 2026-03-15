package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.ProductBatch;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class BatchResponse {
    private UUID id;
    private String batchCode;
    private String qrCode;

    // Ürün bilgisi
    private UUID productId;
    private String productName;
    private String productCategory;
    private String productSku;

    // Üretici bilgisi
    private String producerName;
    private String organizationName;

    private Double quantity;
    private String unit;
    private LocalDate productionDate;
    private LocalDate expiryDate;
    private String originLocation;
    private String status;
    private String blockchainTxHash;
    private LocalDateTime createdAt;

    public static BatchResponse from(ProductBatch b) {
        return BatchResponse.builder()
                .id(b.getId())
                .batchCode(b.getBatchCode())
                .qrCode(b.getQrCode())
                .productId(b.getProduct().getId())
                .productName(b.getProduct().getName())
                .productCategory(b.getProduct().getCategory())
                .productSku(b.getProduct().getSku())
                .producerName(b.getProducer().getFullName())
                .organizationName(b.getOrganization().getName())
                .quantity(b.getQuantity())
                .unit(b.getUnit())
                .productionDate(b.getProductionDate())
                .expiryDate(b.getExpiryDate())
                .originLocation(b.getOriginLocation())
                .status(b.getStatus().name())
                .blockchainTxHash(b.getBlockchainTxHash())
                .createdAt(b.getCreatedAt())
                .build();
    }
}
