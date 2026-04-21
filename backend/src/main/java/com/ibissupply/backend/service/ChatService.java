package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.request.ChatRequest;
import com.ibissupply.backend.dto.response.ChatResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChatService {

    @Value("${groq.api-key:}")
    private String apiKey;

    private static final String GROQ_URL =
            "https://api.groq.com/openai/v1/chat/completions";

    private static final String MODEL = "llama-3.3-70b-versatile";

    private static final String SYSTEM_PROMPT = """
            Sen IbisSupply platformunun yapay zeka asistanısın. \
            IbisSupply, blockchain tabanlı bir gıda tedarik zinciri izlenebilirlik sistemidir.

            Platform özellikleri:
            - Batch (üretim partisi) oluşturma ve takip
            - Sevkiyat yönetimi ve soğuk zincir takibi
            - Kalite kontrol kayıtları (INSPECTOR rolü)
            - Tarımsal üretim kayıtları (PRODUCER rolü)
            - QR kod ile ürün izleme (tüketiciler için)
            - AI ile anomali tespiti ve gecikme tahmini
            - Blockchain ile değiştirilemez kayıt (Ethereum/Hardhat)
            - Rol tabanlı erişim: ADMIN, PRODUCER, PROCESSOR, LOGISTICS, WAREHOUSE, INSPECTOR, RETAILER, CUSTOMER

            Kullanıcılara gıda güvenliği, tedarik zinciri yönetimi, soğuk zincir standartları \
            ve platform kullanımı konularında yardımcı ol. \
            Türkçe konuş, kısa ve anlaşılır yanıtlar ver.
            """;

    public ChatResponse chat(ChatRequest request) {
        if (apiKey == null || apiKey.isBlank()) {
            return ChatResponse.builder()
                    .reply("AI asistan şu an kullanılamıyor. GROQ_API_KEY ortam değişkeni ayarlanmamış.")
                    .build();
        }

        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));

        List<ChatRequest.HistoryMessage> history = request.getHistory();
        if (history != null) {
            for (ChatRequest.HistoryMessage h : history) {
                messages.add(Map.of("role", h.getRole(), "content", h.getContent()));
            }
        }
        messages.add(Map.of("role", "user", "content", request.getMessage()));

        Map<String, Object> body = new HashMap<>();
        body.put("model", MODEL);
        body.put("messages", messages);
        body.put("max_tokens", 1024);
        body.put("temperature", 0.7);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        RestTemplate restTemplate = new RestTemplate();
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    GROQ_URL, entity, Map.class);

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> choices =
                    (List<Map<String, Object>>) response.get("choices");

            @SuppressWarnings("unchecked")
            Map<String, String> msg =
                    (Map<String, String>) choices.get(0).get("message");

            return ChatResponse.builder().reply(msg.get("content")).build();
        } catch (Exception e) {
            return ChatResponse.builder()
                    .reply("Yanıt alınamadı: " + e.getMessage())
                    .build();
        }
    }
}
