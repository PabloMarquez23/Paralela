package com.upsglam.backend.repository;

import com.upsglam.backend.dto.PostFeedDto;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import java.util.UUID;

@Repository
public interface PostRepository extends ReactiveCrudRepository<com.upsglam.backend.model.Post, UUID> {

    @Query("SELECT p.id, p.user_id, p.image_url, p.processed_url, p.description, p.applied_mask, p.kernel_time_ms, p.created_at, prof.username " +
           "FROM public.posts p " +
           "JOIN public.profiles prof ON p.user_id = prof.id " +
           "ORDER BY p.created_at DESC")
    Flux<PostFeedDto> findAllPostsWithUsernames();
}