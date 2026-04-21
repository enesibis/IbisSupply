package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.response.ComplaintResponse;
import com.ibissupply.backend.entity.Complaint;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.enums.ComplaintStatus;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.ComplaintRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ComplaintService {

    private final ComplaintRepository complaintRepository;
    private final UserRepository userRepository;
    private final BatchRepository batchRepository;

    public ComplaintResponse createComplaint(String email, String subject, String description, String batchCode) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        ProductBatch batch = batchCode != null && !batchCode.isBlank()
                ? batchRepository.findByBatchCode(batchCode).orElse(null)
                : null;

        Complaint complaint = complaintRepository.save(Complaint.builder()
                .user(user)
                .batch(batch)
                .subject(subject)
                .description(description)
                .build());

        return ComplaintResponse.builder()
                .id(complaint.getId().toString())
                .subject(complaint.getSubject())
                .status(complaint.getStatus().name())
                .message("Şikayetiniz alındı, en kısa sürede incelenecektir.")
                .build();
    }

    public List<ComplaintResponse> getMyComplaints(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        return complaintRepository.findByUserIdOrderByCreatedAtDesc(user.getId()).stream()
                .map(c -> ComplaintResponse.builder()
                        .id(c.getId().toString())
                        .subject(c.getSubject())
                        .description(c.getDescription())
                        .status(c.getStatus().name())
                        .batchCode(c.getBatch() != null ? c.getBatch().getBatchCode() : null)
                        .createdAt(c.getCreatedAt().toString())
                        .build())
                .collect(Collectors.toList());
    }

    public List<ComplaintResponse> getAllComplaints() {
        return complaintRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(c -> ComplaintResponse.builder()
                        .id(c.getId().toString())
                        .subject(c.getSubject())
                        .description(c.getDescription())
                        .status(c.getStatus().name())
                        .userEmail(c.getUser().getEmail())
                        .userName(c.getUser().getFullName())
                        .batchCode(c.getBatch() != null ? c.getBatch().getBatchCode() : null)
                        .createdAt(c.getCreatedAt().toString())
                        .build())
                .collect(Collectors.toList());
    }

    public ComplaintResponse resolveComplaint(UUID id) {
        Complaint complaint = complaintRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Şikayet bulunamadı"));
        complaint.setStatus(ComplaintStatus.RESOLVED);
        complaintRepository.save(complaint);
        return ComplaintResponse.builder()
                .id(complaint.getId().toString())
                .subject(complaint.getSubject())
                .status(complaint.getStatus().name())
                .build();
    }
}
