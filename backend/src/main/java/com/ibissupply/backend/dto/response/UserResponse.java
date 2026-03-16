package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.User;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class UserResponse {
    private UUID id;
    private String fullName;
    private String email;
    private String phone;
    private String role;
    private String organizationName;
    private boolean active;
    private LocalDateTime createdAt;

    public static UserResponse from(User u) {
        return UserResponse.builder()
                .id(u.getId())
                .fullName(u.getFullName())
                .email(u.getEmail())
                .phone(u.getPhone())
                .role(u.getRole().name())
                .organizationName(u.getOrganization() != null ? u.getOrganization().getName() : null)
                .active(u.isActive())
                .createdAt(u.getCreatedAt())
                .build();
    }
}
