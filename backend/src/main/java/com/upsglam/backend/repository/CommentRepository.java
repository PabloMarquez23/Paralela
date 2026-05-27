package com.upsglam.backend.repository;

import com.upsglam.backend.model.Comment;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import java.util.UUID;

@Repository
public interface CommentRepository extends ReactiveCrudRepository<Comment, UUID> {

    /**
     * 🎯 Trae los comentarios haciendo JOIN con perfiles para rellenar el campo transient 'username'
     */
    @Query("SELECT c.id, c.post_id, c.user_id, c.content, c.created_at, p.username " +
           "FROM public.comments c " +
           "JOIN public.profiles p ON c.user_id = p.id " +
           "WHERE c.post_id = :postId " +
           "ORDER BY c.created_at ASC")
    Flux<Comment> findByPostIdWithUsername(UUID postId);
}