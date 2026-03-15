package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.request.ShipmentEventRequest;
import com.ibissupply.backend.dto.request.ShipmentRequest;
import com.ibissupply.backend.dto.response.ShipmentEventResponse;
import com.ibissupply.backend.dto.response.ShipmentResponse;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.Shipment;
import com.ibissupply.backend.entity.ShipmentEvent;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.enums.ShipmentStatus;
import com.ibissupply.backend.enums.UserRole;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.ShipmentEventRepository;
import com.ibissupply.backend.repository.ShipmentRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ShipmentService {

    private final ShipmentRepository shipmentRepository;
    private final ShipmentEventRepository eventRepository;
    private final BatchRepository batchRepository;
    private final UserRepository userRepository;

    @Transactional
    public ShipmentResponse createShipment(ShipmentRequest req) {
        User currentUser = getCurrentUser();

        ProductBatch batch = batchRepository.findById(req.getBatchId())
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));

        String shipmentCode = generateShipmentCode();

        Shipment shipment = Shipment.builder()
                .shipmentCode(shipmentCode)
                .batch(batch)
                .fromLocation(req.getFromLocation())
                .toLocation(req.getToLocation())
                .carrier(currentUser)
                .vehiclePlate(req.getVehiclePlate())
                .status(ShipmentStatus.PENDING)
                .build();

        Shipment saved = shipmentRepository.save(shipment);

        // Otomatik CREATED olayı ekle
        ShipmentEvent createdEvent = ShipmentEvent.builder()
                .shipment(saved)
                .eventType("CREATED")
                .locationAddress(req.getFromLocation())
                .notes(req.getNotes())
                .recordedBy(currentUser)
                .eventTime(LocalDateTime.now())
                .build();
        eventRepository.save(createdEvent);

        return ShipmentResponse.from(saved);
    }

    public List<ShipmentResponse> getMyShipments() {
        User currentUser = getCurrentUser();
        List<Shipment> shipments;

        if (currentUser.getRole() == UserRole.ADMIN) {
            shipments = shipmentRepository.findAllByOrderByCreatedAtDesc();
        } else {
            shipments = shipmentRepository.findByCarrierIdOrderByCreatedAtDesc(currentUser.getId());
        }

        return shipments.stream().map(ShipmentResponse::from).toList();
    }

    public ShipmentResponse getShipmentById(UUID id) {
        Shipment shipment = shipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sevkiyat bulunamadı"));
        ShipmentResponse response = ShipmentResponse.from(shipment);
        response.setEvents(
                eventRepository.findByShipmentIdOrderByEventTimeAsc(id)
                        .stream().map(ShipmentEventResponse::from).toList()
        );
        return response;
    }

    @Transactional
    public ShipmentEventResponse addEvent(UUID shipmentId, ShipmentEventRequest req) {
        User currentUser = getCurrentUser();

        Shipment shipment = shipmentRepository.findById(shipmentId)
                .orElseThrow(() -> new RuntimeException("Sevkiyat bulunamadı"));

        ShipmentEvent event = ShipmentEvent.builder()
                .shipment(shipment)
                .eventType(req.getEventType())
                .locationAddress(req.getLocationAddress())
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .temperature(req.getTemperature())
                .humidity(req.getHumidity())
                .notes(req.getNotes())
                .recordedBy(currentUser)
                .eventTime(LocalDateTime.now())
                .build();

        // Durum güncellemeleri
        if ("DEPARTED".equals(req.getEventType())) {
            shipment.setStatus(ShipmentStatus.IN_TRANSIT);
            shipment.setDepartureTime(LocalDateTime.now());
            shipmentRepository.save(shipment);
        } else if ("DELIVERED".equals(req.getEventType())) {
            shipment.setStatus(ShipmentStatus.DELIVERED);
            shipment.setArrivalTime(LocalDateTime.now());
            shipmentRepository.save(shipment);
        }

        return ShipmentEventResponse.from(eventRepository.save(event));
    }

    @Transactional
    public ShipmentResponse deliver(UUID id) {
        User currentUser = getCurrentUser();
        Shipment shipment = shipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sevkiyat bulunamadı"));

        shipment.setStatus(ShipmentStatus.DELIVERED);
        shipment.setArrivalTime(LocalDateTime.now());
        shipmentRepository.save(shipment);

        ShipmentEvent event = ShipmentEvent.builder()
                .shipment(shipment)
                .eventType("DELIVERED")
                .locationAddress(shipment.getToLocation())
                .notes("Teslimat tamamlandı")
                .recordedBy(currentUser)
                .eventTime(LocalDateTime.now())
                .build();
        eventRepository.save(event);

        return getShipmentById(id);
    }

    private String generateShipmentCode() {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmm"));
        String random = String.format("%04d", (int)(Math.random() * 9999));
        return "SHIP-" + timestamp + "-" + random;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
    }
}
