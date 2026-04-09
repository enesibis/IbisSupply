package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FavoriteRepository extends JpaRepository<Favorite, UUID> {
    List<Favorite> findByUserId(UUID userId);
    Optional<Favorite> findByUserIdAndBatchId(UUID userId, UUID batchId);
    boolean existsByUserIdAndBatchId(UUID userId, UUID batchId);
    void deleteByUserIdAndBatchId(UUID userId, UUID batchId);
}
