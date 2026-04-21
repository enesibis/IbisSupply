package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.request.FarmRecordRequest;
import com.ibissupply.backend.dto.response.FarmRecordResponse;
import com.ibissupply.backend.entity.FarmRecord;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.FarmRecordRepository;
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
public class FarmRecordService {

    private final FarmRecordRepository farmRecordRepository;
    private final BatchRepository batchRepository;
    private final UserRepository userRepository;
    private final BlockchainService blockchainService;

    public FarmRecordResponse create(FarmRecordRequest request) {
        User producer = getCurrentUser();

        ProductBatch batch = batchRepository.findById(request.getBatchId())
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));

        FarmRecord record = FarmRecord.builder()
                .batch(batch)
                .producer(producer)
                .fieldLocation(request.getFieldLocation())
                .plantingDate(request.getPlantingDate())
                .harvestDate(request.getHarvestDate())
                .irrigationType(request.getIrrigationType())
                .totalIrrigationHours(request.getTotalIrrigationHours())
                .pesticides(request.getPesticides())
                .fertilizers(request.getFertilizers())
                .notes(request.getNotes())
                .build();

        FarmRecord saved = farmRecordRepository.save(record);

        blockchainService.registerFarmRecord(
                batch.getBatchCode(),
                request.getFieldLocation(),
                request.getIrrigationType(),
                request.getPesticides()
        ).ifPresent(txHash -> {
            saved.setBlockchainTxHash(txHash);
            farmRecordRepository.save(saved);
        });

        return FarmRecordResponse.from(saved);
    }

    public List<FarmRecordResponse> getByBatch(UUID batchId) {
        return farmRecordRepository.findByBatchIdOrderByCreatedAtDesc(batchId)
                .stream().map(FarmRecordResponse::from).collect(Collectors.toList());
    }

    public List<FarmRecordResponse> getMine() {
        User producer = getCurrentUser();
        return farmRecordRepository.findByProducerIdOrderByCreatedAtDesc(producer.getId())
                .stream().map(FarmRecordResponse::from).collect(Collectors.toList());
    }

    public void delete(UUID id) {
        User currentUser = getCurrentUser();
        FarmRecord record = farmRecordRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarımsal kayıt bulunamadı"));

        if (currentUser.getRole() != com.ibissupply.backend.enums.UserRole.ADMIN
                && !record.getProducer().getId().equals(currentUser.getId())) {
            throw new RuntimeException("Bu kaydı silme yetkiniz yok");
        }

        farmRecordRepository.deleteById(id);
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
    }
}
