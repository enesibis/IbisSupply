package com.ibissupply.backend.service;

import com.ibissupply.backend.entity.Complaint;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.ComplaintRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ComplaintService {

    private final ComplaintRepository complaintRepository;
    private final UserRepository userRepository;
    private final BatchRepository batchRepository;

    public Map<String, Object> createComplaint(String email, String subject, String description, String batchCode) {
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

        HashMap<String, Object> result = new HashMap<>();
        result.put("id", complaint.getId().toString());
        result.put("subject", complaint.getSubject());
        result.put("status", complaint.getStatus().name());
        result.put("message", "Şikayetiniz alındı, en kısa sürede incelenecektir.");
        return result;
    }

    public List<Map<String, Object>> getMyComplaints(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        return complaintRepository.findByUserIdOrderByCreatedAtDesc(user.getId()).stream().map(c -> {
            HashMap<String, Object> map = new HashMap<>();
            map.put("id", c.getId().toString());
            map.put("subject", c.getSubject());
            map.put("description", c.getDescription());
            map.put("status", c.getStatus().name());
            map.put("batchCode", c.getBatch() != null ? c.getBatch().getBatchCode() : null);
            map.put("createdAt", c.getCreatedAt().toString());
            return (Map<String, Object>) map;
        }).collect(Collectors.toList());
    }

    public List<Map<String, Object>> getAllComplaints() {
        return complaintRepository.findAllByOrderByCreatedAtDesc().stream().map(c -> {
            HashMap<String, Object> map = new HashMap<>();
            map.put("id", c.getId().toString());
            map.put("subject", c.getSubject());
            map.put("description", c.getDescription());
            map.put("status", c.getStatus().name());
            map.put("userEmail", c.getUser().getEmail());
            map.put("userName", c.getUser().getFullName());
            map.put("batchCode", c.getBatch() != null ? c.getBatch().getBatchCode() : null);
            map.put("createdAt", c.getCreatedAt().toString());
            return (Map<String, Object>) map;
        }).collect(Collectors.toList());
    }
}
