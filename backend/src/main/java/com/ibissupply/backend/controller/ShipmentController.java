package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.request.ShipmentEventRequest;
import com.ibissupply.backend.dto.request.ShipmentRequest;
import com.ibissupply.backend.dto.response.ShipmentEventResponse;
import com.ibissupply.backend.dto.response.ShipmentResponse;
import com.ibissupply.backend.service.ShipmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shipments")
@RequiredArgsConstructor
public class ShipmentController {

    private final ShipmentService shipmentService;

    /** Sevkiyat oluştur — lojistik rolleri */
    @PostMapping
    @PreAuthorize("hasAnyAuthority('LOGISTICS','ADMIN')")
    public ResponseEntity<ShipmentResponse> create(@Valid @RequestBody ShipmentRequest req) {
        return ResponseEntity.ok(shipmentService.createShipment(req));
    }

    /** Sevkiyat listesi — tüm iş rolleri */
    @GetMapping
    @PreAuthorize("hasAnyAuthority('ADMIN','PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','INSPECTOR','RETAILER')")
    public ResponseEntity<List<ShipmentResponse>> list() {
        return ResponseEntity.ok(shipmentService.getMyShipments());
    }

    /** Sevkiyat detayı — tüm iş rolleri */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ADMIN','PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','INSPECTOR','RETAILER')")
    public ResponseEntity<ShipmentResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.getShipmentById(id));
    }

    /** Sevkiyat olayı ekle — lojistik rolleri */
    @PostMapping("/{id}/events")
    @PreAuthorize("hasAnyAuthority('LOGISTICS','WAREHOUSE','ADMIN')")
    public ResponseEntity<ShipmentEventResponse> addEvent(
            @PathVariable UUID id,
            @Valid @RequestBody ShipmentEventRequest req) {
        return ResponseEntity.ok(shipmentService.addEvent(id, req));
    }

    /** Teslim et — lojistik ve depo */
    @PutMapping("/{id}/deliver")
    @PreAuthorize("hasAnyAuthority('LOGISTICS','WAREHOUSE','ADMIN')")
    public ResponseEntity<ShipmentResponse> deliver(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.deliver(id));
    }

    /** Anomali sonucu — iş rolleri */
    @GetMapping("/{id}/anomaly")
    @PreAuthorize("hasAnyAuthority('ADMIN','PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','INSPECTOR','RETAILER')")
    public ResponseEntity<?> getAnomaly(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.getAnomalyResult(id));
    }

    /** Sevkiyat sil — sadece PENDING statü */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('LOGISTICS','ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        shipmentService.delete(id);
        return ResponseEntity.noContent().build();
    }

    /** Gecikme tahmini — iş rolleri */
    @GetMapping("/{id}/delay")
    @PreAuthorize("hasAnyAuthority('ADMIN','PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','INSPECTOR','RETAILER')")
    public ResponseEntity<?> getDelay(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.getDelayPrediction(id));
    }
}
