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

    @Column("created_at")
    private LocalDateTime createdAt;

    // 🎯 Campo transitorio: No se mapea en las columnas de Supabase.
    // Sirve para capturar el nombre del alumno en el JOIN del Feed.
    @Transient
    private String username;

    // 🎯 Bandera transitoria interna para gobernar el comportamiento de inserción de R2DBC
    @Transient
    private boolean isNewEntry = true;

    // Constructor Vacío Obligatorio para Spring
    public Post() {}

    // Constructor Completo
    public Post(UUID id, UUID userId, String imageUrl, String processedUrl, String description, LocalDateTime createdAt, String username) {
        this.id = id;
        this.userId = userId;
        this.imageUrl = imageUrl;
        this.processedUrl = processedUrl;
        this.description = description;
        this.createdAt = createdAt;
        this.username = username;
    }

    // ==============================================================================
    // MÉTODOS OBLIGATORIOS DE LA INTERFAZ PERSISTABLE
    // ==============================================================================

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
    // GETTERS Y SETTERS TRADICIONALES
    // ==============================================================================

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getProcessedUrl() {
        return processedUrl;
    }

    public void setProcessedUrl(String processedUrl) {
        this.processedUrl = processedUrl;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
}