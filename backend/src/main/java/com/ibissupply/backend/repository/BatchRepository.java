package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.enums.BatchStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BatchRepository extends JpaRepository<ProductBatch, UUID> {
    List<ProductBatch> findByOrganizationIdOrderByCreatedAtDesc(UUID organizationId);
    List<ProductBatch> findByProducerIdOrderByCreatedAtDesc(UUID producerId);
    List<ProductBatch> findByStatusOrderByCreatedAtDesc(BatchStatus status);
    Optional<ProductBatch> findByBatchCode(String batchCode);
    Optional<ProductBatch> findByQrCode(String qrCode);
    boolean existsByBatchCode(String batchCode);
}
