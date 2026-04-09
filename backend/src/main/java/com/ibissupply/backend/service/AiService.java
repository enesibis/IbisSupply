package com.ibissupply.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
public class AiService {

    @Value("${ai.enabled:false}")
    private boolean enabled;

    @Value("${ai.base-url:http://localhost:8000}")
    private String baseUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Sevkiyat sıcaklık logları için anomali analizi.
     * temperatures: ShipmentEvent'lerden toplanan sıcaklık listesi.
     */
    public Optional<AnomalyResult> analyzeAnomaly(List<Double> temperatures,
                                                   String category,
                                                   double durationHours) {
        if (!enabled || temperatures.isEmpty()) return Optional.empty();
        try {
            ObjectNode body = objectMapper.createObjectNode();
            ArrayNode temps = body.putArray("temperatures");
            temperatures.forEach(temps::add);
            body.put("category", category != null ? category.toUpperCase() : "DEFAULT");
            body.put("duration_hours", durationHours);

            String json = objectMapper.writeValueAsString(body);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<String> entity = new HttpEntity<>(json, headers);

            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    baseUrl + "/ai/analyze-anomaly",
                    HttpMethod.POST, entity, JsonNode.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode r = response.getBody();
                return Optional.of(new AnomalyResult(
                        r.get("is_anomaly").asBoolean(),
                        r.get("risk_level").asText(),
                        r.get("risk_score").asDouble(),
                        r.has("anomaly_type") && !r.get("anomaly_type").isNull()
                                ? r.get("anomaly_type").asText() : null,
                        r.get("recommended_action").asText()
                ));
            }
        } catch (Exception e) {
            log.warn("[AI] analyzeAnomaly hata: {}", e.getMessage());
        }
        return Optional.empty();
    }

    /**
     * Batch için 0-100 risk skoru.
     */
    public Optional<RiskScore> computeRiskScore(List<Double> temperatures,
                                                 String category,
                                                 double durationHours,
                                                 int expiryDaysRemaining,
                                                 String qualityCheckResult) {
        if (!enabled) return Optional.empty();
        try {
            ObjectNode body = objectMapper.createObjectNode();
            ArrayNode temps = body.putArray("temperatures");
            temperatures.forEach(temps::add);
            body.put("category", category != null ? category.toUpperCase() : "DEFAULT");
            body.put("duration_hours", durationHours);
            body.put("expiry_days_remaining", expiryDaysRemaining);
            if (qualityCheckResult != null) {
                body.put("quality_check_result", qualityCheckResult);
            }

            String json = objectMapper.writeValueAsString(body);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<String> entity = new HttpEntity<>(json, headers);

            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    baseUrl + "/ai/risk-score",
                    HttpMethod.POST, entity, JsonNode.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode r = response.getBody();
                return Optional.of(new RiskScore(
                        r.get("risk_score").asDouble(),
                        r.get("risk_level").asText()
                ));
            }
        } catch (Exception e) {
            log.warn("[AI] computeRiskScore hata: {}", e.getMessage());
        }
        return Optional.empty();
    }

    /**
     * Ürün kategorisi için raf ömrü standartlarını AI servisinden çeker.
     */
    public Map<String, Object> getShelfLife(String category) {
        try {
            ResponseEntity<JsonNode> response = restTemplate.getForEntity(
                    baseUrl + "/ai/shelf-life/" + category.toUpperCase(),
                    JsonNode.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return objectMapper.convertValue(response.getBody(),
                        new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {});
            }
        } catch (Exception e) {
            log.warn("[AI] getShelfLife hata: {}", e.getMessage());
        }
        return Map.of("category", category, "optimal_days", 90, "min_days", 30, "max_days", 365);
    }

    // ── İç record'lar ────────────────────────────────────────────────────────

    public record AnomalyResult(
            boolean isAnomaly,
            String riskLevel,
            double riskScore,
            String anomalyType,
            String recommendedAction
    ) {}

    public record RiskScore(
            double score,
            String level
    ) {}
}
