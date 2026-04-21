package com.ibissupply.backend.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class FavoriteResponse {
    private String favoriteId;
    private String batchId;
    private String batchCode;
    private String qrCode;
    private String productName;
    private String status;
    private String addedAt;
    private String message;
}
