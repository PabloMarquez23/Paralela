package com.upsglam.backend.repository;

import com.upsglam.backend.model.Comment;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.util.UUID;

@Repository
public interface CommentRepository extends ReactiveCrudRepository<Comment, UUID> {

    @Query("SELECT c.id, c.post_id, c.user_id, c.content, c.parent_comment_id, c.created_at, p.username AS username " +
           "FROM public.comments c " +
           "JOIN public.profiles p ON c.user_id = p.id " +
           "WHERE c.post_id = :postId AND c.parent_comment_id IS NULL " +
           "ORDER BY c.created_at ASC")
    Flux<Comment> findRootCommentsByPostId(UUID postId);

    @Query("SELECT c.id, c.post_id, c.user_id, c.content, c.parent_comment_id, c.created_at, p.username AS username " +
           "FROM public.comments c " +
           "JOIN public.profiles p ON c.user_id = p.id " +
           "WHERE c.parent_comment_id = :parentCommentId " +
           "ORDER BY c.created_at ASC")
    Flux<Comment> findRepliesByParentId(UUID parentCommentId);

    // ==============================================================================
    // OPERACIONES PARA GESTIÓN DE LIKES EN COMENTARIOS (comment_likes)
    // ==============================================================================

    @Query("SELECT COUNT(*) FROM public.comment_likes WHERE comment_id = :commentId")
    Mono<Long> countLikesByCommentId(UUID commentId);

    @Query("SELECT EXISTS(SELECT 1 FROM public.comment_likes WHERE comment_id = :commentId AND user_id = :userId)")
    Mono<Boolean> existsLikeByCommentIdAndUserId(UUID commentId, UUID userId);

    @Modifying
    @Query("INSERT INTO public.comment_likes (comment_id, user_id) VALUES (:commentId, :userId)")
    Mono<Void> insertCommentLike(UUID commentId, UUID userId);

    @Modifying
    @Query("DELETE FROM public.comment_likes WHERE comment_id = :commentId AND user_id = :userId")
    Mono<Void> deleteCommentLike(UUID commentId, UUID userId);
    
    // ==============================================================================
    // INYECCIÓN DE NOTIFICACIONES DINÁMICAS (En base a tu tabla SQL)
    // ==============================================================================
    
    @Modifying
    @Query("INSERT INTO public.notifications (user_id, source_user_id, type, post_id, comment_id) " +
           "VALUES (:targetUserId, :sourceUserId, :type, :postId, :commentId)")
    Mono<Void> createNotification(UUID targetUserId, UUID sourceUserId, String type, UUID postId, UUID commentId);

    @Query("SELECT user_id FROM public.posts WHERE id = :postId")
    Mono<UUID> findPostOwnerId(UUID postId);

    @Query("SELECT user_id FROM public.comments WHERE id = :commentId")
    Mono<UUID> findCommentOwnerId(UUID commentId);
}