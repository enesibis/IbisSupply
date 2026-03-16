package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.request.QualityCheckRequest;
import com.ibissupply.backend.dto.response.QualityCheckResponse;
import com.ibissupply.backend.service.QualityCheckService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/quality-checks")
@RequiredArgsConstructor
public class QualityCheckController {

    private final QualityCheckService qualityCheckService;

    @PostMapping
    @PreAuthorize("hasAnyAuthority('INSPECTOR', 'ADMIN')")
    public ResponseEntity<QualityCheckResponse> create(@RequestBody QualityCheckRequest request) {
        return ResponseEntity.ok(qualityCheckService.createCheck(request));
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<QualityCheckResponse>> myChecks() {
        return ResponseEntity.ok(qualityCheckService.getMyChecks());
    }

    @GetMapping("/batch/{batchId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<QualityCheckResponse>> byBatch(@PathVariable UUID batchId) {
        return ResponseEntity.ok(qualityCheckService.getChecksByBatch(batchId));
    }
}
