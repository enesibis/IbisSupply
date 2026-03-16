package com.ibissupply.backend.dto.request;

import com.ibissupply.backend.enums.UserRole;
import lombok.Data;

@Data
public class AdminUpdateRoleRequest {
    private UserRole role;
}
