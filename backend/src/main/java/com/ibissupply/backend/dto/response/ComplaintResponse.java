package com.ibissupply.backend.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ComplaintResponse {
    private String id;
    private String subject;
    private String description;
    private String status;
    private String batchCode;
    private String userEmail;
    private String userName;
    private String createdAt;
    private String message;
}
