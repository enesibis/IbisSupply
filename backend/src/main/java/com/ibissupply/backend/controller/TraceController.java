package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.response.TraceResponse;
import com.ibissupply.backend.service.TraceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/trace")
@RequiredArgsConstructor
public class TraceController {

    private final TraceService traceService;

    @GetMapping("/batch/{batchCode}")
    public ResponseEntity<TraceResponse> traceByBatchCode(@PathVariable String batchCode) {
        return ResponseEntity.ok(traceService.traceByBatchCode(batchCode));
    }

    @GetMapping("/qr/{qrCode}")
    public ResponseEntity<TraceResponse> traceByQrCode(@PathVariable String qrCode) {
        return ResponseEntity.ok(traceService.traceByQrCode(qrCode));
    }
}
