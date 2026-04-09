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
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ShipmentService {

    private final ShipmentRepository shipmentRepository;
    private final ShipmentEventRepository eventRepository;
    private final BatchRepository batchRepository;
    private final UserRepository userRepository;
    private final BlockchainService blockchainService;
    private final AiService aiService;

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

        blockchainService.registerShipment(
                shipmentCode,
                batch.getBatchCode(),
                req.getFromLocation(),
                req.getToLocation()
        ).ifPresent(txHash -> {
            saved.setBlockchainTxHash(txHash);
            shipmentRepository.save(saved);
        });

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

        ShipmentEvent saved = eventRepository.save(event);

        // Sıcaklık logu varsa AI anomali analizi tetikle
        if (req.getTemperature() != null) {
            List<Double> allTemps = eventRepository
                    .findByShipmentIdOrderByEventTimeAsc(shipmentId)
                    .stream()
                    .filter(e -> e.getTemperature() != null)
                    .map(ShipmentEvent::getTemperature)
                    .collect(Collectors.toList());

            double durationHours = shipment.getDepartureTime() != null
                    ? Math.max(1.0, Duration.between(shipment.getDepartureTime(), LocalDateTime.now()).toMinutes() / 60.0)
                    : 1.0;

            String category = shipment.getBatch() != null && shipment.getBatch().getProduct() != null
                    ? shipment.getBatch().getProduct().getCategory()
                    : "DEFAULT";

            aiService.analyzeAnomaly(allTemps, category, durationHours)
                    .ifPresent(result -> {
                        if (result.isAnomaly()) {
                            log.warn("[AI] Anomali tespit edildi — Sevkiyat: {}, Seviye: {}, Tip: {}",
                                    shipment.getShipmentCode(), result.riskLevel(), result.anomalyType());
                        }
                    });
        }

        return ShipmentEventResponse.from(saved);
    }

    @Transactional
    public ShipmentResponse deliver(UUID id) {
        User currentUser = getCurrentUser();
        Shipment shipment = shipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sevkiyat bulunamadı"));

        shipment.setStatus(ShipmentStatus.DELIVERED);
        shipment.setArrivalTime(LocalDateTime.now());
        shipmentRepository.save(shipment);

        blockchainService.deliverShipment(shipment.getShipmentCode())
                .ifPresent(txHash -> {
                    shipment.setBlockchainTxHash(txHash);
                    shipmentRepository.save(shipment);
                });

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

    public Map<String, Object> getAnomalyResult(UUID id) {
        Shipment shipment = shipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sevkiyat bulunamadı"));

        List<Double> temps = eventRepository.findByShipmentIdOrderByEventTimeAsc(id)
                .stream()
                .filter(e -> e.getTemperature() != null)
                .map(ShipmentEvent::getTemperature)
                .collect(Collectors.toList());

        if (temps.isEmpty()) {
            Map<String, Object> empty = new HashMap<>();
            empty.put("isAnomaly", false);
            empty.put("riskLevel", "LOW");
            empty.put("riskScore", 0.0);
            empty.put("recommendedAction", "Sıcaklık verisi yok.");
            empty.put("hasData", false);
            return empty;
        }

        double durationHours = shipment.getDepartureTime() != null
                ? Math.max(1.0, Duration.between(shipment.getDepartureTime(), LocalDateTime.now()).toMinutes() / 60.0)
                : 1.0;

        String category = shipment.getBatch() != null && shipment.getBatch().getProduct() != null
                ? shipment.getBatch().getProduct().getCategory()
                : "DEFAULT";

        return aiService.analyzeAnomaly(temps, category, durationHours)
                .map(r -> {
                    Map<String, Object> result = new HashMap<>();
                    result.put("isAnomaly", r.isAnomaly());
                    result.put("riskLevel", r.riskLevel());
                    result.put("riskScore", r.riskScore());
                    result.put("anomalyType", r.anomalyType() != null ? r.anomalyType() : "");
                    result.put("recommendedAction", r.recommendedAction());
                    result.put("temperatureCount", temps.size());
                    result.put("hasData", true);
                    return result;
                })
                .orElseGet(() -> {
                    Map<String, Object> fallback = new HashMap<>();
                    fallback.put("isAnomaly", false);
                    fallback.put("riskLevel", "UNKNOWN");
                    fallback.put("riskScore", 0.0);
                    fallback.put("recommendedAction", "AI servisi kullanılamıyor.");
                    fallback.put("hasData", false);
                    return fallback;
                });
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
