package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.request.FarmRecordRequest;
import com.ibissupply.backend.dto.response.FarmRecordResponse;
import com.ibissupply.backend.service.FarmRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/farm-records")
@RequiredArgsConstructor
public class FarmRecordController {

    private final FarmRecordService farmRecordService;

    /** Yeni tarımsal kayıt oluştur (PRODUCER) */
    @PostMapping
    public ResponseEntity<FarmRecordResponse> create(@RequestBody FarmRecordRequest request) {
        return ResponseEntity.ok(farmRecordService.create(request));
    }

    /** Kendi kayıtlarını listele */
    @GetMapping
    public ResponseEntity<List<FarmRecordResponse>> getMine() {
        return ResponseEntity.ok(farmRecordService.getMine());
    }

    /** Belirli bir batch'e ait tüm tarımsal kayıtlar */
    @GetMapping("/batch/{batchId}")
    public ResponseEntity<List<FarmRecordResponse>> getByBatch(@PathVariable UUID batchId) {
        return ResponseEntity.ok(farmRecordService.getByBatch(batchId));
    }
}
