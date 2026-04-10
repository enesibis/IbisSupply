package com.ibissupply.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "farm_records")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FarmRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "batch_id", nullable = false)
    private ProductBatch batch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "producer_id", nullable = false)
    private User producer;

    // Tarla bilgisi
    private String fieldLocation;
    private LocalDate plantingDate;
    private LocalDate harvestDate;

    // Sulama
    private String irrigationType;       // DRIP, SPRINKLER, FLOOD, MANUAL
    private Double totalIrrigationHours;

    // İlaç kayıtları — JSON array string
    // Örnek: [{"name":"Fungisit X","date":"2026-03-10","dosageMlPerL":2.5,"daysBeforeHarvest":14}]
    @Column(columnDefinition = "TEXT")
    private String pesticides;

    // Gübre kayıtları — JSON array string
    // Örnek: [{"name":"NPK 20-20-20","date":"2026-02-15","amountKgPerDecare":5.0}]
    @Column(columnDefinition = "TEXT")
    private String fertilizers;

    private String notes;

    // Blockchain TX hash
    private String blockchainTxHash;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
