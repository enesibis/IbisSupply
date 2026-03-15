package com.ibissupply.backend.dto.request;

import com.ibissupply.backend.enums.BatchStatus;
import lombok.Data;

@Data
public class BatchStatusRequest {
    private BatchStatus status;
}
