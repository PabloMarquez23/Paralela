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

    @GetMapping("/comments/post/{postId}")
    public Flux<Comment> getComments(@PathVariable UUID postId) {
        return interactionService.getCommentsByPostId(postId);
    }

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
                .map(count -> Map.of("likesCount", count)); // 🎯 Key exacta que busca Flutter
    }

    @GetMapping("/likes/check")
    public Mono<Map<String, Object>> checkUserLike(@RequestParam UUID postId, @RequestParam UUID userId) {
        return interactionService.isLikedByUser(postId, userId)
                .defaultIfEmpty(false)
                .map(liked -> Map.of("liked", liked)); // 🎯 Key exacta que busca Flutter
    }
}