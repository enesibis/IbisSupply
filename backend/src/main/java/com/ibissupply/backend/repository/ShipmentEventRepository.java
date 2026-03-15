package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.ShipmentEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ShipmentEventRepository extends JpaRepository<ShipmentEvent, UUID> {
    List<ShipmentEvent> findByShipmentIdOrderByEventTimeAsc(UUID shipmentId);
}
