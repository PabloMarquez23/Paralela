package com.upsglam.backend.repository;

import com.upsglam.backend.model.Like;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;
import java.util.UUID;

@Repository
public interface LikeRepository extends ReactiveCrudRepository<Like, UUID> {
    
    Mono<Long> countByPostId(UUID postId);
    Mono<Boolean> existsByPostIdAndUserId(UUID postId, UUID userId);
    Mono<Void> deleteByPostIdAndUserId(UUID postId, UUID userId);
}