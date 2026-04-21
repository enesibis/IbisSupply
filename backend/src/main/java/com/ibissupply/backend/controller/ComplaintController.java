package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.response.ComplaintResponse;
import com.ibissupply.backend.service.ComplaintService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/complaints")
@RequiredArgsConstructor
public class ComplaintController {

    private final ComplaintService complaintService;

    @PostMapping
    @PreAuthorize("hasAuthority('CUSTOMER')")
    public ResponseEntity<ComplaintResponse> create(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(complaintService.createComplaint(
                userDetails.getUsername(),
                body.get("subject"),
                body.get("description"),
                body.get("batchCode")));
    }

    @GetMapping("/my")
    @PreAuthorize("hasAuthority('CUSTOMER')")
    public ResponseEntity<List<ComplaintResponse>> myComplaints(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(complaintService.getMyComplaints(userDetails.getUsername()));
    }

    @GetMapping
    @PreAuthorize("hasAnyAuthority('ADMIN','INSPECTOR')")
    public ResponseEntity<List<ComplaintResponse>> all() {
        return ResponseEntity.ok(complaintService.getAllComplaints());
    }

    @PatchMapping("/{id}/resolve")
    @PreAuthorize("hasAnyAuthority('ADMIN','INSPECTOR')")
    public ResponseEntity<ComplaintResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(complaintService.resolveComplaint(id));
    }
}
