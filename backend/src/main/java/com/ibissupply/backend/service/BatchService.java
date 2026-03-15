package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.request.BatchRequest;
import com.ibissupply.backend.dto.request.BatchStatusRequest;
import com.ibissupply.backend.dto.response.BatchResponse;
import com.ibissupply.backend.entity.Product;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.enums.UserRole;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.ProductRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BatchService {

    private final BatchRepository batchRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    public BatchResponse createBatch(BatchRequest req) {
        User currentUser = getCurrentUser();

        Product product = productRepository.findById(req.getProductId())
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı"));

        String batchCode = generateBatchCode();
        String qrCode = UUID.randomUUID().toString();

        ProductBatch batch = ProductBatch.builder()
                .batchCode(batchCode)
                .qrCode(qrCode)
                .product(product)
                .producer(currentUser)
                .organization(currentUser.getOrganization())
                .quantity(req.getQuantity())
                .unit(req.getUnit())
                .productionDate(req.getProductionDate())
                .expiryDate(req.getExpiryDate())
                .originLocation(req.getOriginLocation())
                .build();

        return BatchResponse.from(batchRepository.save(batch));
    }

    public List<BatchResponse> getMyBatches() {
        User currentUser = getCurrentUser();
        List<ProductBatch> batches;

        if (currentUser.getRole() == UserRole.ADMIN) {
            batches = batchRepository.findAll();
        } else {
            batches = batchRepository.findByOrganizationIdOrderByCreatedAtDesc(
                    currentUser.getOrganization().getId());
        }

        return batches.stream().map(BatchResponse::from).toList();
    }

    public BatchResponse getBatchById(UUID id) {
        ProductBatch batch = batchRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));
        return BatchResponse.from(batch);
    }

    public BatchResponse getBatchByCode(String batchCode) {
        ProductBatch batch = batchRepository.findByBatchCode(batchCode)
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));
        return BatchResponse.from(batch);
    }

    public BatchResponse updateStatus(UUID id, BatchStatusRequest req) {
        ProductBatch batch = batchRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));
        batch.setStatus(req.getStatus());
        return BatchResponse.from(batchRepository.save(batch));
    }

    private String generateBatchCode() {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmm"));
        String random = String.format("%04d", (int)(Math.random() * 9999));
        return "BTCH-" + timestamp + "-" + random;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
    }
}
