package com.ibissupply.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "shipment_events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ShipmentEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipment_id", nullable = false)
    private Shipment shipment;

    @Column(nullable = false)
    private String eventType; // DEPARTED, CHECKPOINT, TEMPERATURE_LOG, DELIVERED, INCIDENT

    private String locationAddress;
    private Double latitude;
    private Double longitude;

    private Double temperature;
    private Double humidity;

    private String notes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recorded_by")
    private User recordedBy;

    // Blockchain reference (only for critical events)
    private String blockchainTxHash;

    @Column(nullable = false)
    private LocalDateTime eventTime;
}
