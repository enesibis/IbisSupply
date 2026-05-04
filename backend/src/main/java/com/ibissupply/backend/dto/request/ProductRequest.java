package com.ibissupply.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

@Data
public class ProductRequest {

    @NotBlank
    private String name;

    @NotBlank
    private String category;

    @NotBlank
    private String sku;

    private String description;

    @NotBlank
    private String unit;

    private Double minSafeTemp;
    private Double maxSafeTemp;

    @NotNull
    private UUID organizationId;
}
