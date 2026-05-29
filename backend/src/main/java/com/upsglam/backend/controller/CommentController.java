package com.upsglam.backend.controller;

import com.upsglam.backend.model.Comment;
import com.upsglam.backend.service.InteractionService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/interactions")
@CrossOrigin(origins = "*")
public class CommentController {

    private final InteractionService interactionService;

    public CommentController(InteractionService interactionService) {
        this.interactionService = interactionService;
    }

    @PostMapping("/comments")
    public Mono<Comment> addComment(@RequestBody Comment comment) {
        return interactionService.saveComment(comment);
    }

    /**
     * 🚀 Devuelve el árbol completo de comentarios raíz con sus respuestas anidadas,
     * métricas de likes y estado adaptado para el usuario actual.
     */
    @GetMapping("/comments/post/{postId}")
    public Flux<Comment> getComments(@PathVariable UUID postId, @RequestParam(required = false) UUID userId) {
        // Si userId no viene en los query params, enviamos un UUID vacío ficticio para la verificación de likes
        UUID finalUserId = (userId != null) ? userId : UUID.fromString("00000000-0000-0000-0000-000000000000");
        return interactionService.getCommentsTreeByPostId(postId, finalUserId);
    }

    // ==============================================================================
    // CONTROLADORES AGREGADOS PARA MANEJO DE LIKES EN COMENTARIOS (HILOS)
    // ==============================================================================

    @PostMapping("/comments/likes/toggle")
    public Mono<Map<String, Object>> toggleCommentLike(@RequestBody Map<String, String> body) {
        UUID commentId = UUID.fromString(body.get("commentId"));
        UUID userId = UUID.fromString(body.get("userId"));
        return interactionService.toggleCommentLike(commentId, userId)
                .map(status -> Map.of("status", status));
    }

    // ==============================================================================
    // CONTROLADORES ANTERIORES PARA POSTS (MANTENIDOS E INTEGRADOS)
    // ==============================================================================

    @PostMapping("/likes/toggle")
    public Mono<Map<String, Object>> toggleLike(@RequestBody Map<String, String> body) {
        UUID postId = UUID.fromString(body.get("postId"));
        UUID userId = UUID.fromString(body.get("userId"));
        return interactionService.toggleLike(postId, userId)
                .map(status -> Map.of("status", status));
    }

    @GetMapping("/likes/count/{postId}")
    public Mono<Map<String, Object>> getLikesCount(@PathVariable UUID postId) {
        return interactionService.getLikesCount(postId)
                .defaultIfEmpty(0L)
                .map(count -> Map.of("likesCount", count));
    }

    @GetMapping("/likes/check")
    public Mono<Map<String, Object>> checkUserLike(@RequestParam UUID postId, @RequestParam UUID userId) {
        return interactionService.isLikedByUser(postId, userId)
                .defaultIfEmpty(false)
                .map(liked -> Map.of("liked", liked));
    }
}