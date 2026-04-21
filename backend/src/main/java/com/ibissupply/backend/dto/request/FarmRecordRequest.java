package com.ibissupply.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class FarmRecordRequest {

    @NotNull
    private UUID batchId;

    @NotBlank
    private String fieldLocation;
    private LocalDate plantingDate;
    private LocalDate harvestDate;

    /** DRIP | SPRINKLER | FLOOD | MANUAL */
    private String irrigationType;
    private Double totalIrrigationHours;

    /** JSON string — ilaç listesi */
    private String pesticides;

    /** JSON string — gübre listesi */
    private String fertilizers;

    private String notes;
}
