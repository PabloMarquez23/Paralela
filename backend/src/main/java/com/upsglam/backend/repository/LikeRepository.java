package com.upsglam.backend.repository;

import com.upsglam.backend.model.Like;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;
import java.util.UUID;

@Repository
public interface LikeRepository extends ReactiveCrudRepository<Like, UUID> {
    
    @Query("SELECT COUNT(*) FROM public.likes WHERE post_id = :postId")
    Mono<Long> countByPostId(UUID postId);
    
    @Query("SELECT EXISTS(SELECT 1 FROM public.likes WHERE post_id = :postId AND user_id = :userId)")
    Mono<Boolean> existsByPostIdAndUserId(UUID postId, UUID userId);
    
    @Modifying
    @Query("DELETE FROM public.likes WHERE post_id = :postId AND user_id = :userId")
    Mono<Void> deleteByPostIdAndUserId(UUID postId, UUID userId);
}