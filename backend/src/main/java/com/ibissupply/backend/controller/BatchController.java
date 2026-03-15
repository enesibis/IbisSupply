package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.request.BatchRequest;
import com.ibissupply.backend.dto.request.BatchStatusRequest;
import com.ibissupply.backend.dto.response.BatchResponse;
import com.ibissupply.backend.service.BatchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/batches")
@RequiredArgsConstructor
public class BatchController {

    private final BatchService batchService;

    @PostMapping
    @PreAuthorize("hasAnyAuthority('PRODUCER','PROCESSOR','ADMIN')")
    public ResponseEntity<BatchResponse> create(@RequestBody BatchRequest req) {
        return ResponseEntity.ok(batchService.createBatch(req));
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<BatchResponse>> list() {
        return ResponseEntity.ok(batchService.getMyBatches());
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<BatchResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(batchService.getBatchById(id));
    }

    @GetMapping("/code/{batchCode}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<BatchResponse> getByCode(@PathVariable String batchCode) {
        return ResponseEntity.ok(batchService.getBatchByCode(batchCode));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyAuthority('PRODUCER','PROCESSOR','LOGISTICS','WAREHOUSE','ADMIN')")
    public ResponseEntity<BatchResponse> updateStatus(
            @PathVariable UUID id,
            @RequestBody BatchStatusRequest req) {
        return ResponseEntity.ok(batchService.updateStatus(id, req));
    }
}
