package com.upsglam.backend.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.Transient;
import org.springframework.data.domain.Persistable;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;
import java.time.LocalDateTime;
import java.util.UUID;

@Table("likes")
public class Like implements Persistable<UUID> {

    @Id
    private UUID id;

    @Column("post_id")
    private UUID postId;

    @Column("user_id")
    private UUID userId;

    @Column("created_at")
    private LocalDateTime createdAt;

    @Transient
    private boolean isNewEntry = true;

    public Like() {}

    public Like(UUID id, UUID postId, UUID userId, LocalDateTime createdAt) {
        this.id = id;
        this.postId = postId;
        this.userId = userId;
        this.createdAt = createdAt;
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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}