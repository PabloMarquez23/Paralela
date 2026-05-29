package com.upsglam.backend.controller;

import com.upsglam.backend.model.Profile;
import com.upsglam.backend.repository.ProfileRepository;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/profiles")
@CrossOrigin(origins = "*")
public class ProfileController {

    private final ProfileRepository profileRepository;

    public ProfileController(ProfileRepository profileRepository) {
        this.profileRepository = profileRepository;
    }

    /**
     * 🎯 Obtiene los datos del perfil de un estudiante por su ID de Supabase
     */
    @GetMapping("/{userId}")
    public Mono<Profile> getProfile(@PathVariable UUID userId) {
        return profileRepository.findById(userId);
    }

    /**
     * 🎯 Modifica la biografía/descripción del perfil en la base de datos relacional
     */
    @PutMapping("/update-bio")
    public Mono<Void> updateBio(@RequestBody Map<String, String> body) {
        UUID userId = UUID.fromString(body.get("userId"));
        String bio = body.get("bio");
        return profileRepository.updateBio(userId, bio);
    }

    /**
     * 🚀 Vincula la relación Follow entre dos estudiantes e inyecta la alerta
     */
    @PostMapping("/follow")
    public Mono<Map<String, String>> followStudent(@RequestBody Map<String, String> body) {
        UUID followerId = UUID.fromString(body.get("followerId"));
        UUID followingId = UUID.fromString(body.get("followingId"));

        if (followerId.equals(followingId)) {
            return Mono.just(Map.of("status", "CANNOT_FOLLOW_YOURSELF"));
        }

        return profileRepository.existsFollow(followerId, followingId)
                .flatMap(exists -> {
                    if (exists) {
                        return Mono.just(Map.of("status", "ALREADY_FOLLOWING"));
                    } else {
                        return profileRepository.addFollow(followerId, followingId)
                                .then(profileRepository.createFollowNotification(followingId, followerId))
                                .thenReturn(Map.of("status", "SUCCESS"));
                    }
                });
    }
}