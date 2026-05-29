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
    // 📩 SERVICIO DE COMENTARIOS ACADÉMICOS (RECURSIVOS E HILADOS)
    // ==============================================================================

    /**
     * 🎯 Método fallback por si algún componente plano sigue llamando a la lista antigua
     */
    public Flux<Comment> getCommentsByPostId(UUID postId) {
        return commentRepository.findRootCommentsByPostId(postId);
    }

    /**
     * 🚀 Construye la estructura jerárquica en árbol con métricas de likes adaptadas 
     * para que Flutter renderice las respuestas e hilos de conversación.
     */
    public Flux<Comment> getCommentsTreeByPostId(UUID postId, UUID userId) {
        return commentRepository.findRootCommentsByPostId(postId)
                .flatMap(rootComment -> 
                    Mono.zip(
                        commentRepository.countLikesByCommentId(rootComment.getId()).defaultIfEmpty(0L),
                        commentRepository.existsLikeByCommentIdAndUserId(rootComment.getId(), userId).defaultIfEmpty(false)
                    ).flatMap(tuple -> {
                        rootComment.setLikesCount(tuple.getT1());
                        rootComment.setLikedByCurrentUser(tuple.getT2());
                        return resolveRepliesRecursively(rootComment, userId).thenReturn(rootComment);
                    })
                );
    }

    /**
     * 🛠️ Helper recursivo reactivo para profundizar en las respuestas de los hilos
     */
    private Mono<Void> resolveRepliesRecursively(Comment parentComment, UUID userId) {
        return commentRepository.findRepliesByParentId(parentComment.getId())
                .flatMap(reply -> 
                    Mono.zip(
                        commentRepository.countLikesByCommentId(reply.getId()).defaultIfEmpty(0L),
                        commentRepository.existsLikeByCommentIdAndUserId(reply.getId(), userId).defaultIfEmpty(false)
                    ).flatMap(tuple -> {
                        reply.setLikesCount(tuple.getT1());
                        reply.setLikedByCurrentUser(tuple.getT2());
                        return resolveRepliesRecursively(reply, userId).thenReturn(reply);
                    })
                )
                .collectList()
                .doOnNext(parentComment::setReplies)
                .then();
    }

    /**
     * 🎯 Guarda un comentario (Raíz o Respuesta) e inyecta la notificación en Supabase
     */
    @Transactional
    public Mono<Comment> saveComment(Comment comment) {
        if (comment.getId() == null) {
            comment.setId(UUID.randomUUID());
        }
        comment.setCreatedAt(LocalDateTime.now());
        comment.setNewEntry(true);

        return commentRepository.save(comment)
                .flatMap(savedComment -> {
                    // Caso A: El comentario es una RESPUESTA (HILO ANIDADO) -> Alerta al dueño del comentario padre
                    if (savedComment.getParentCommentId() != null) {
                        return commentRepository.findCommentOwnerId(savedComment.getParentCommentId())
                                .flatMap(targetUserId -> {
                                    if (!targetUserId.equals(savedComment.getUserId())) {
                                        return commentRepository.createNotification(
                                                targetUserId, 
                                                savedComment.getUserId(), 
                                                "REPLY", 
                                                savedComment.getPostId(), 
                                                savedComment.getId()
                                        );
                                    }
                                    return Mono.empty();
                                })
                                .thenReturn(savedComment);
                    } else {
                        // Caso B: El comentario es RAÍZ -> Alerta al dueño de la publicación (Post)
                        return commentRepository.findPostOwnerId(savedComment.getPostId())
                                .flatMap(targetUserId -> {
                                    if (!targetUserId.equals(savedComment.getUserId())) {
                                        return commentRepository.createNotification(
                                                targetUserId, 
                                                savedComment.getUserId(), 
                                                "COMMENT", 
                                                savedComment.getPostId(), 
                                                savedComment.getId()
                                        );
                                    }
                                    return Mono.empty();
                                })
                                .thenReturn(savedComment);
                    }
                });
    }

    /**
     * ⚙️ Alterna (Toggle) el Like en un COMENTARIO específico e inyecta alertas en caliente
     */
    @Transactional
    public Mono<String> toggleCommentLike(UUID commentId, UUID userId) {
        return commentRepository.existsLikeByCommentIdAndUserId(commentId, userId)
                .flatMap(exists -> {
                    if (exists) {
                        return commentRepository.deleteCommentLike(commentId, userId).thenReturn("UNLIKED");
                    } else {
                        return commentRepository.insertCommentLike(commentId, userId)
                                .then(commentRepository.findCommentOwnerId(commentId))
                                .flatMap(targetUserId -> {
                                    if (!targetUserId.equals(userId)) {
                                        return commentRepository.createNotification(
                                                targetUserId, userId, "LIKE_COMMENT", null, commentId
                                        );
                                    }
                                    return Mono.empty();
                                })
                                .thenReturn("LIKED");
                    }
                });
    }

    // ==============================================================================
    // ❤️ SERVICIO DE REACCIONES EN POSTS (MANTENIDO E INTEGRADO CON NOTIFICACIONES)
    // ==============================================================================

    /**
     * 🎯 Remueve o agrega una reacción al post e inyecta alertas dinámicas para el dueño de la foto.
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
                        .then(commentRepository.findPostOwnerId(postId))
                        .flatMap(targetUserId -> {
                            if (!targetUserId.equals(userId)) {
                                return commentRepository.createNotification(
                                        targetUserId, userId, "LIKE_POST", postId, null
                                );
                            }
                            return Mono.empty();
                        })
                        .then(Mono.just("ADDED"));
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