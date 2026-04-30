package com.ibissupply.backend.controller;

import com.ibissupply.backend.dto.response.FavoriteResponse;
import com.ibissupply.backend.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/user/favorites")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<FavoriteResponse>> getFavorites(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(favoriteService.getFavorites(userDetails.getUsername()));
    }

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FavoriteResponse> addFavorite(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(
                favoriteService.addFavorite(userDetails.getUsername(), body.get("batchCode")));
    }

    @DeleteMapping("/{batchCode}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> removeFavorite(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String batchCode) {
        favoriteService.removeFavorite(userDetails.getUsername(), batchCode);
        return ResponseEntity.noContent().build();
    }
}
