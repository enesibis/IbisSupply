package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.response.FavoriteResponse;
import com.ibissupply.backend.entity.Favorite;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.FavoriteRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final BatchRepository batchRepository;

    public List<FavoriteResponse> getFavorites(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        return favoriteRepository.findByUserId(user.getId()).stream()
                .map(f -> {
                    ProductBatch b = f.getBatch();
                    return FavoriteResponse.builder()
                            .favoriteId(f.getId().toString())
                            .batchId(b.getId().toString())
                            .batchCode(b.getBatchCode())
                            .qrCode(b.getQrCode())
                            .productName(b.getProduct() != null ? b.getProduct().getName() : "")
                            .status(b.getStatus() != null ? b.getStatus().name() : "")
                            .addedAt(f.getCreatedAt().toString())
                            .build();
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public FavoriteResponse addFavorite(String email, String batchCode) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        ProductBatch batch = batchRepository.findByBatchCode(batchCode)
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı: " + batchCode));

        if (favoriteRepository.existsByUserIdAndBatchId(user.getId(), batch.getId())) {
            throw new RuntimeException("Bu ürün zaten favorilerinizde");
        }

        Favorite fav = favoriteRepository.save(Favorite.builder()
                .user(user)
                .batch(batch)
                .build());

        return FavoriteResponse.builder()
                .favoriteId(fav.getId().toString())
                .batchCode(batch.getBatchCode())
                .productName(batch.getProduct() != null ? batch.getProduct().getName() : "")
                .message("Favorilere eklendi")
                .build();
    }

    @Transactional
    public void removeFavorite(String email, String batchCode) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        ProductBatch batch = batchRepository.findByBatchCode(batchCode)
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı"));
        favoriteRepository.deleteByUserIdAndBatchId(user.getId(), batch.getId());
    }
}
