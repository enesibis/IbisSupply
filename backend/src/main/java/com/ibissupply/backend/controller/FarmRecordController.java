package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.request.FarmRecordRequest;
import com.ibissupply.backend.dto.response.FarmRecordResponse;
import com.ibissupply.backend.service.FarmRecordService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/farm-records")
@RequiredArgsConstructor
public class FarmRecordController {

    private final FarmRecordService farmRecordService;

    /** Yeni tarımsal kayıt oluştur — sadece PRODUCER veya ADMIN */
    @PostMapping
    @PreAuthorize("hasAnyAuthority('PRODUCER','ADMIN')")
    public ResponseEntity<FarmRecordResponse> create(@Valid @RequestBody FarmRecordRequest request) {
        return ResponseEntity.ok(farmRecordService.create(request));
    }

    /** Kendi kayıtlarını listele — PRODUCER ve ADMIN */
    @GetMapping
    @PreAuthorize("hasAnyAuthority('PRODUCER','ADMIN')")
    public ResponseEntity<List<FarmRecordResponse>> getMine() {
        return ResponseEntity.ok(farmRecordService.getMine());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('PRODUCER','ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        farmRecordService.delete(id);
        return ResponseEntity.noContent().build();
    }

    /** Belirli bir batch'e ait tarımsal kayıtlar — tüm iş rolleri görebilir */
    @GetMapping("/batch/{batchId}")
    @PreAuthorize("hasAnyAuthority('ADMIN','PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','INSPECTOR','RETAILER')")
    public ResponseEntity<List<FarmRecordResponse>> getByBatch(@PathVariable UUID batchId) {
        return ResponseEntity.ok(farmRecordService.getByBatch(batchId));
    }
}
