package com.ibissupply.backend.controller;

import com.ibissupply.backend.repository.ProductRepository;
import com.ibissupply.backend.service.AiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductRepository productRepository;
    private final AiService aiService;

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
                    return m;
                })
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }
}
