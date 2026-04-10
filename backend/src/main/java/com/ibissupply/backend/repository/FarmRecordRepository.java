package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.FarmRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FarmRecordRepository extends JpaRepository<FarmRecord, UUID> {

    List<FarmRecord> findByBatchIdOrderByCreatedAtDesc(UUID batchId);

    List<FarmRecord> findByProducerIdOrderByCreatedAtDesc(UUID producerId);
}
