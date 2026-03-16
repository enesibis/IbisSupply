package com.ibissupply.backend.dto.request;

import com.ibissupply.backend.enums.UserRole;
import lombok.Data;

@Data
public class AdminCreateUserRequest {
    private String fullName;
    private String email;
    private String password;
    private String phone;
    private UserRole role;
}
