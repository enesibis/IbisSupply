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
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shipments")
@RequiredArgsConstructor
public class ShipmentController {

    private final ShipmentService shipmentService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ShipmentResponse> create(@Valid @RequestBody ShipmentRequest req) {
        return ResponseEntity.ok(shipmentService.createShipment(req));
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ShipmentResponse>> list() {
        return ResponseEntity.ok(shipmentService.getMyShipments());
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ShipmentResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.getShipmentById(id));
    }

    @PostMapping("/{id}/events")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ShipmentEventResponse> addEvent(
            @PathVariable UUID id,
            @Valid @RequestBody ShipmentEventRequest req) {
        return ResponseEntity.ok(shipmentService.addEvent(id, req));
    }

    @PutMapping("/{id}/deliver")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ShipmentResponse> deliver(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.deliver(id));
    }
}
