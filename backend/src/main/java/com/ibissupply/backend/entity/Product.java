package com.ibissupply.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "products")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String category; // FRUIT, VEGETABLE, DAIRY, MEAT, GRAIN, etc.

    @Column(unique = true, nullable = false)
    private String sku;

    private String description;

    @Column(nullable = false)
    @Builder.Default
    private String unit = "KG"; // KG, PIECE, LITER

    // Safe temperature range for cold chain monitoring
    private Double minSafeTemp;
    private Double maxSafeTemp;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
