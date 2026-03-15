package com.ibissupply.backend.repository;

import com.ibissupply.backend.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface ProductRepository extends JpaRepository<Product, UUID> {
    List<Product> findByOrganizationId(UUID organizationId);
    boolean existsBySku(String sku);
}
