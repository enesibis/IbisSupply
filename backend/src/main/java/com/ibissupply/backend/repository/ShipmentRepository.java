package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.Shipment;
import com.ibissupply.backend.enums.ShipmentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ShipmentRepository extends JpaRepository<Shipment, UUID> {
    List<Shipment> findByCarrierIdOrderByCreatedAtDesc(UUID carrierId);
    List<Shipment> findByBatchIdOrderByCreatedAtDesc(UUID batchId);
    List<Shipment> findByStatusOrderByCreatedAtDesc(ShipmentStatus status);
    List<Shipment> findAllByOrderByCreatedAtDesc();
    Optional<Shipment> findByShipmentCode(String shipmentCode);
    boolean existsByShipmentCode(String shipmentCode);
}
