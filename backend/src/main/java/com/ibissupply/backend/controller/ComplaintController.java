package com.ibissupply.backend.controller;

import com.ibissupply.backend.service.ComplaintService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/complaints")
@RequiredArgsConstructor
public class ComplaintController {

    private final ComplaintService complaintService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(complaintService.createComplaint(
                userDetails.getUsername(),
                body.get("subject"),
                body.get("description"),
                body.get("batchCode")));
    }

    @GetMapping("/my")
    public ResponseEntity<List<Map<String, Object>>> myComplaints(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(complaintService.getMyComplaints(userDetails.getUsername()));
    }

    @GetMapping
    @PreAuthorize("hasAnyAuthority('ADMIN','INSPECTOR')")
    public ResponseEntity<List<Map<String, Object>>> all() {
        return ResponseEntity.ok(complaintService.getAllComplaints());
    }
}
