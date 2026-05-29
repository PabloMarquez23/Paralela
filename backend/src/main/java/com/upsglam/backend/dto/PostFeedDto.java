package com.upsglam.backend.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class PostFeedDto {
    private UUID id;
    private UUID userId;
    private String imageUrl;
    private String processedUrl;
    private String description;
    private String appliedMask;
    private Double kernelTimeMs;
    private LocalDateTime createdAt;
    private String username; // Mapeo directo y limpio

    public PostFeedDto() {}

    // GETTERS Y SETTERS COMPLETOS
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getProcessedUrl() { return processedUrl; }
    public void setProcessedUrl(String processedUrl) { this.processedUrl = processedUrl; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getAppliedMask() { return appliedMask; }
    public void setAppliedMask(String appliedMask) { this.appliedMask = appliedMask; }
    public Double getKernelTimeMs() { return kernelTimeMs; }
    public void setKernelTimeMs(Double kernelTimeMs) { this.kernelTimeMs = kernelTimeMs; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}