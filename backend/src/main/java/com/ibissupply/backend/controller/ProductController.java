package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.request.ProductRequest;
import com.ibissupply.backend.entity.Organization;
import com.ibissupply.backend.entity.Product;
import com.ibissupply.backend.enums.ProductCategory;
import com.ibissupply.backend.repository.OrganizationRepository;
import com.ibissupply.backend.repository.ProductRepository;
import com.ibissupply.backend.service.AiService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductRepository productRepository;
    private final OrganizationRepository organizationRepository;
    private final AiService aiService;

    @GetMapping("/categories")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<String>> categories() {
        List<String> cats = Arrays.stream(ProductCategory.values())
                .filter(c -> c != ProductCategory.DEFAULT)
                .map(Enum::name)
                .collect(Collectors.toList());
        return ResponseEntity.ok(cats);
    }

    @GetMapping("/shelf-life/{category}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> shelfLife(@PathVariable String category) {
        return ResponseEntity.ok(aiService.getShelfLife(category));
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Map<String, Object>>> list() {
        List<Map<String, Object>> result = productRepository.findAll().stream()
                .map(p -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", p.getId() != null ? p.getId().toString() : "");
                    m.put("name", p.getName() != null ? p.getName() : "");
                    m.put("category", p.getCategory() != null ? p.getCategory() : "");
                    m.put("sku", p.getSku() != null ? p.getSku() : "");
                    m.put("unit", p.getUnit() != null ? p.getUnit() : "KG");
                    m.put("minSafeTemp", p.getMinSafeTemp());
                    m.put("maxSafeTemp", p.getMaxSafeTemp());
                    return m;
                })
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Map<String, Object>> create(@Valid @RequestBody ProductRequest req) {
        if (!ProductCategory.isValid(req.getCategory())) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Geçersiz kategori: " + req.getCategory()
                            + ". Geçerli kategoriler: FRUIT, VEGETABLE, GRAIN, DAIRY, LEGUME, HERB, NUT, MEAT, OIL"
            ));
        }
        if (productRepository.existsBySku(req.getSku())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Bu SKU zaten mevcut: " + req.getSku()));
        }

        Organization org = organizationRepository.findById(req.getOrganizationId())
                .orElseThrow(() -> new RuntimeException("Organizasyon bulunamadı"));

        Product saved = productRepository.save(Product.builder()
                .name(req.getName())
                .category(req.getCategory().toUpperCase())
                .sku(req.getSku().toUpperCase())
                .description(req.getDescription())
                .unit(req.getUnit())
                .minSafeTemp(req.getMinSafeTemp())
                .maxSafeTemp(req.getMaxSafeTemp())
                .organization(org)
                .build());

        Map<String, Object> m = new HashMap<>();
        m.put("id", saved.getId().toString());
        m.put("name", saved.getName());
        m.put("category", saved.getCategory());
        m.put("sku", saved.getSku());
        m.put("unit", saved.getUnit());
        return ResponseEntity.ok(m);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable java.util.UUID id) {
        productRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
