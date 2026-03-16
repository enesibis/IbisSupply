package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.request.QualityCheckRequest;
import com.ibissupply.backend.dto.response.QualityCheckResponse;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.QualityCheck;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.QualityCheckRepository;
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
public class QualityCheckService {

    private final QualityCheckRepository qualityCheckRepository;
    private final BatchRepository batchRepository;
    private final UserRepository userRepository;

    public QualityCheckResponse createCheck(QualityCheckRequest request) {
        User inspector = getCurrentUser();

        ProductBatch batch = batchRepository.findById(request.getBatchId())
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));

        QualityCheck check = QualityCheck.builder()
                .batch(batch)
                .inspector(inspector)
                .result(request.getResult())
                .temperature(request.getTemperature())
                .humidity(request.getHumidity())
                .contaminationDetected(request.getContaminationDetected())
                .notes(request.getNotes())
                .build();

        return QualityCheckResponse.from(qualityCheckRepository.save(check));
    }

    public List<QualityCheckResponse> getMyChecks() {
        User user = getCurrentUser();
        return qualityCheckRepository.findByInspectorIdOrderByCheckedAtDesc(user.getId())
                .stream().map(QualityCheckResponse::from).collect(Collectors.toList());
    }

    public List<QualityCheckResponse> getChecksByBatch(UUID batchId) {
        return qualityCheckRepository.findByBatchIdOrderByCheckedAtDesc(batchId)
                .stream().map(QualityCheckResponse::from).collect(Collectors.toList());
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
    }
}
