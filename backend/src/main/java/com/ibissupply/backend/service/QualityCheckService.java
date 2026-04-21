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
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class QualityCheckService {

    private final QualityCheckRepository qualityCheckRepository;
    private final BatchRepository batchRepository;
    private final UserRepository userRepository;
    private final BlockchainService blockchainService;
    private final AlertService alertService;

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

        QualityCheck saved = qualityCheckRepository.save(check);

        blockchainService.registerQualityCheck(
                batch.getBatchCode(),
                request.getResult().name(),
                request.getNotes()
        ).ifPresent(txHash -> {
            saved.setBlockchainTxHash(txHash);
            qualityCheckRepository.save(saved);
        });

        // Kalite PASSED → NFT sertifikası mint et
        if (request.getResult().name().equals("PASSED")) {
            blockchainService.mintCertificateNFT(
                    batch.getBatchCode(),
                    batch.getProduct().getName()
            ).ifPresent(txHash ->
                    log.info("[NFT] Sertifika mint edildi. Batch: {} TX: {}", batch.getBatchCode(), txHash)
            );
        }

        if (request.getResult().name().equals("FAILED") || request.getResult().name().equals("NEEDS_REVIEW")) {
            alertService.createAlert(
                    "QUALITY_FAIL",
                    request.getResult().name().equals("FAILED") ? "HIGH" : "MEDIUM",
                    "Kalite kontrol " + request.getResult().name() + ": " + batch.getBatchCode()
                            + (request.getNotes() != null ? " — " + request.getNotes() : ""),
                    batch,
                    null
            );
        }

        return QualityCheckResponse.from(saved);
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

    public void delete(UUID id) {
        User currentUser = getCurrentUser();
        QualityCheck check = qualityCheckRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Kalite kontrol kaydı bulunamadı"));

        if (currentUser.getRole() != com.ibissupply.backend.enums.UserRole.ADMIN
                && !check.getInspector().getId().equals(currentUser.getId())) {
            throw new RuntimeException("Bu kaydı silme yetkiniz yok");
        }

        qualityCheckRepository.deleteById(id);
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
    }
}
