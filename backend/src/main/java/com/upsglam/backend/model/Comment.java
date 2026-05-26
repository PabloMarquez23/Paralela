package com.upsglam.backend.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.Transient;
import org.springframework.data.domain.Persistable;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;
import java.time.LocalDateTime;
import java.util.UUID;

@Table("comments")
public class Comment implements Persistable<UUID> {

    @Id
    private UUID id;

    @Column("post_id")
    private UUID postId;

    @Column("user_id")
    private UUID userId;

    private String content;

    @Column("created_at")
    private LocalDateTime createdAt;

    // 🎯 Campo transitorio: No está en la tabla comments, 
    // pero almacena el username del estudiante traído desde el JOIN relacional.
    @Transient
    private String username;

    @Transient
    private boolean isNewEntry = true;

    public Comment() {}

    public Comment(UUID id, UUID postId, UUID userId, String content, LocalDateTime createdAt, String username) {
        this.id = id;
        this.postId = postId;
        this.userId = userId;
        this.content = content;
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
    // GETTERS Y SETTERS COMPLETOS
    // ==============================================================================

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getPostId() {
        return postId;
    }

    public void setPostId(UUID postId) {
        this.postId = postId;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
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