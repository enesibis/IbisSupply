package com.ibissupply.backend.dto.request;

import lombok.Data;
import java.util.List;

@Data
public class ChatRequest {
    private String message;
    private List<HistoryMessage> history;

    @Data
    public static class HistoryMessage {
        private String role;    // "user" or "assistant"
        private String content;
    }
}
