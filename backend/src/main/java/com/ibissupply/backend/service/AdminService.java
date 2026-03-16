package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.request.AdminCreateUserRequest;
import com.ibissupply.backend.dto.request.AdminUpdateRoleRequest;
import com.ibissupply.backend.dto.response.UserResponse;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream()
                .map(UserResponse::from)
                .collect(Collectors.toList());
    }

    public UserResponse createUser(AdminCreateUserRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Bu email zaten kayıtlı");
        }
        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .phone(request.getPhone())
                .role(request.getRole())
                .active(true)
                .build();
        return UserResponse.from(userRepository.save(user));
    }

    public UserResponse updateRole(UUID userId, AdminUpdateRoleRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        user.setRole(request.getRole());
        return UserResponse.from(userRepository.save(user));
    }

    public UserResponse toggleActive(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));
        user.setActive(!user.isActive());
        return UserResponse.from(userRepository.save(user));
    }
}
