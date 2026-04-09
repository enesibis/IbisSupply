package com.ibissupply.backend.service;

import com.ibissupply.backend.entity.Favorite;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.FavoriteRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final BatchRepository batchRepository;

    public List<Map<String, Object>> getFavorites(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        return favoriteRepository.findByUserId(user.getId()).stream().map(f -> {
            ProductBatch b = f.getBatch();
            HashMap<String, Object> map = new HashMap<>();
            map.put("favoriteId", f.getId().toString());
            map.put("batchId", b.getId().toString());
            map.put("batchCode", b.getBatchCode());
            map.put("qrCode", b.getQrCode());
            map.put("productName", b.getProduct() != null ? b.getProduct().getName() : "");
            map.put("status", b.getStatus() != null ? b.getStatus().name() : "");
            map.put("addedAt", f.getCreatedAt().toString());
            return (Map<String, Object>) map;
        }).collect(Collectors.toList());
    }

    @Transactional
    public Map<String, Object> addFavorite(String email, String batchCode) {
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

        HashMap<String, Object> result = new HashMap<>();
        result.put("favoriteId", fav.getId().toString());
        result.put("batchCode", batch.getBatchCode());
        result.put("productName", batch.getProduct() != null ? batch.getProduct().getName() : "");
        result.put("message", "Favorilere eklendi");
        return result;
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
