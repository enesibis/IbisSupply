package com.ibissupply.backend.entity;

import com.ibissupply.backend.enums.CheckResult;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "quality_checks")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class QualityCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "batch_id", nullable = false)
    private ProductBatch batch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inspector_id", nullable = false)
    private User inspector;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CheckResult result;

    private Double temperature;
    private Double humidity;
    private Boolean contaminationDetected;
    private String notes;

    private String blockchainTxHash;

    @CreationTimestamp
    private LocalDateTime checkedAt;
}
