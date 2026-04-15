package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.response.AlertResponse;
import com.ibissupply.backend.service.AlertService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/alerts")
@RequiredArgsConstructor
public class AlertController {

    private final AlertService alertService;

    /** Çözülmemiş uyarılar */
    @GetMapping
    public ResponseEntity<List<AlertResponse>> getUnresolved() {
        return ResponseEntity.ok(alertService.getUnresolved());
    }

    /** Tüm uyarılar (ADMIN) */
    @GetMapping("/all")
    public ResponseEntity<List<AlertResponse>> getAll() {
        return ResponseEntity.ok(alertService.getAll());
    }

    /** Uyarıyı çözüldü yap */
    @PatchMapping("/{id}/resolve")
    public ResponseEntity<AlertResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(alertService.resolve(id));
    }
}
