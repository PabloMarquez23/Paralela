package com.upsglam.backend.service;

import com.upsglam.backend.model.Comment;
import com.upsglam.backend.model.Like;
import com.upsglam.backend.repository.CommentRepository;
import com.upsglam.backend.repository.LikeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class InteractionService {

    private final CommentRepository commentRepository;
    private final LikeRepository likeRepository;

    public InteractionService(CommentRepository commentRepository, LikeRepository likeRepository) {
        this.commentRepository = commentRepository;
        this.likeRepository = likeRepository;
    }

    // ==============================================================================
    // 📩 SERVICIO DE COMENTARIOS ACADÉMICOS
    // ==============================================================================

    /**
     * 🎯 Obtiene los comentarios de un post ordenados por fecha con el username del alumno.
     */
    public Flux<Comment> getCommentsByPostId(UUID postId) {
        return commentRepository.findByPostIdWithUsername(postId);
    }

    /**
     * 🎯 Guarda un nuevo comentario inyectando el ID transaccional asíncrono.
     */
    @Transactional
    public Mono<Comment> saveComment(Comment comment) {
        if (comment.getId() == null) {
            comment.setId(UUID.randomUUID());
        }
        comment.setCreatedAt(LocalDateTime.now());
        comment.setNewEntry(true);
        return commentRepository.save(comment);
    }

    // ==============================================================================
    // ❤️ SERVICIO DE REACCIONES (LIKES ANTI-DUPLICADOS)
    // ==============================================================================

    /**
     * 🎯 Remueve o agrega una reacción según el estado previo del estudiante en la nube.
     */
    @Transactional
    public Mono<String> toggleLike(UUID postId, UUID userId) {
        return likeRepository.existsByPostIdAndUserId(postId, userId)
            .flatMap(exists -> {
                if (exists) {
                    return likeRepository.deleteByPostIdAndUserId(postId, userId)
                        .then(Mono.just("REMOVED"));
                } else {
                    Like newLike = new Like(UUID.randomUUID(), postId, userId, LocalDateTime.now());
                    newLike.setNewEntry(true);
                    return likeRepository.save(newLike)
                        .map(saved -> "ADDED");
                }
            });
    }

    /**
     * 🎯 Retorna el conteo total de "Me gusta" asociados a un post de laboratorio.
     */
    public Mono<Long> getLikesCount(UUID postId) {
        return likeRepository.countByPostId(postId);
    }

    /**
     * 🎯 Verifica de forma atómica si el alumno ya interactuó con la publicación.
     */
    public Mono<Boolean> isLikedByUser(UUID postId, UUID userId) {
        return likeRepository.existsByPostIdAndUserId(postId, userId);
    }
}