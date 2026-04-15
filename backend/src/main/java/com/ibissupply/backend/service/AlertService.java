package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.response.AlertResponse;
import com.ibissupply.backend.entity.Alert;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.Shipment;
import com.ibissupply.backend.repository.AlertRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AlertService {

    private final AlertRepository alertRepository;
    private final UserRepository userRepository;

    /** Diğer servisler tarafından çağrılır — uyarı oluştur */
    public void createAlert(String type, String severity, String message,
                            ProductBatch batch, Shipment shipment) {
        Alert alert = Alert.builder()
                .type(type)
                .severity(severity)
                .message(message)
                .batch(batch)
                .shipment(shipment)
                .resolved(false)
                .build();
        alertRepository.save(alert);
    }

    /** Çözülmemiş uyarıları getir */
    public List<AlertResponse> getUnresolved() {
        return alertRepository.findByResolvedFalseOrderByCreatedAtDesc()
                .stream().map(AlertResponse::from).collect(Collectors.toList());
    }

    /** Tüm uyarıları getir (ADMIN) */
    public List<AlertResponse> getAll() {
        return alertRepository.findAllByOrderByCreatedAtDesc()
                .stream().map(AlertResponse::from).collect(Collectors.toList());
    }

    /** Uyarıyı çözüldü olarak işaretle */
    public AlertResponse resolve(UUID id) {
        Alert alert = alertRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Uyarı bulunamadı"));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        userRepository.findByEmail(auth.getName()).ifPresent(alert::setResolvedBy);

        alert.setResolved(true);
        return AlertResponse.from(alertRepository.save(alert));
    }
}
