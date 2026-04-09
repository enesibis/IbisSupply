package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.Complaint;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ComplaintRepository extends JpaRepository<Complaint, UUID> {
    List<Complaint> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<Complaint> findAllByOrderByCreatedAtDesc();
}
