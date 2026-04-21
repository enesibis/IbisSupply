package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.response.AlertResponse;
import com.ibissupply.backend.service.AlertService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/alerts")
@RequiredArgsConstructor
public class AlertController {

    private final AlertService alertService;

    /** Çözülmemiş uyarılar — iş rolleri (CUSTOMER hariç) */
    @GetMapping
    @PreAuthorize("hasAnyAuthority('ADMIN','PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','INSPECTOR','RETAILER')")
    public ResponseEntity<List<AlertResponse>> getUnresolved() {
        return ResponseEntity.ok(alertService.getUnresolved());
    }

    /** Tüm uyarılar — sadece ADMIN */
    @GetMapping("/all")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<List<AlertResponse>> getAll() {
        return ResponseEntity.ok(alertService.getAll());
    }

    /** Uyarıyı çözüldü yap — ADMIN veya INSPECTOR */
    @PatchMapping("/{id}/resolve")
    @PreAuthorize("hasAnyAuthority('ADMIN','INSPECTOR')")
    public ResponseEntity<AlertResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(alertService.resolve(id));
    }
}
