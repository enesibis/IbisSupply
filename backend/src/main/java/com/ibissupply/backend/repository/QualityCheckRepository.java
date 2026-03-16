package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.QualityCheck;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface QualityCheckRepository extends JpaRepository<QualityCheck, UUID> {
    List<QualityCheck> findByBatchIdOrderByCheckedAtDesc(UUID batchId);
    List<QualityCheck> findByInspectorIdOrderByCheckedAtDesc(UUID inspectorId);
}
