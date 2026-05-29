package com.upsglam.backend.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.Transient;
import org.springframework.data.domain.Persistable;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;
import java.time.LocalDateTime;
import java.util.UUID;

@Table("posts")
public class Post implements Persistable<UUID> {

    @Id
    private UUID id;

    @Column("user_id")
    private UUID userId;

    @Column("image_url")
    private String imageUrl;

    @Column("processed_url")
    private String processedUrl;

    private String description;

    @Column("applied_mask")
    private String appliedMask; // 🎯 REQUERIMIENTO: Almacena la máscara auto-calculada

    @Column("kernel_time_ms")
    private Double kernelTimeMs; // 🎯 REQUERIMIENTO: Guarda el tiempo del kernel

    @Column("created_at")
    private LocalDateTime createdAt;

    @Transient
    private String username;

    @Transient
    private boolean isNewEntry = true;

    public Post() {}

    public Post(UUID id, UUID userId, String imageUrl, String processedUrl, String description, String appliedMask, Double kernelTimeMs, LocalDateTime createdAt, String username) {
        this.id = id;
        this.userId = userId;
        this.imageUrl = imageUrl;
        this.processedUrl = processedUrl;
        this.description = description;
        this.appliedMask = appliedMask;
        this.kernelTimeMs = kernelTimeMs;
        this.createdAt = createdAt;
        this.username = username;
    }

    @Override
    public UUID getId() {
        return this.id;
    }

    @Override
    @Transient
    public boolean isNew() {
        return this.isNewEntry;
    }

    public void setNewEntry(boolean isNewEntry) {
        this.isNewEntry = isNewEntry;
    }

    // ==============================================================================
    // GETTERS Y SETTERS
    // ==============================================================================

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