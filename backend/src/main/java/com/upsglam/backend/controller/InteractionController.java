package com.upsglam.backend.controller;

import com.upsglam.backend.model.Comment;
import com.upsglam.backend.model.Like;
import com.upsglam.backend.service.InteractionService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/interaction")
@CrossOrigin(origins = "*")
public class InteractionController {

    private final InteractionService service;

    public InteractionController(InteractionService service) {
        this.service = service;
    }

    // 1. Agregar un comentario a un Post
    @PostMapping("/comments")
    public Mono<Comment> postComment(@RequestBody Comment comment) {
        return service.addComment(comment);
    }

    // 2. Obtener todos los comentarios de un Post específico
    @GetMapping("/comments/{postId}")
    public Flux<Comment> getComments(@PathVariable Integer postId) {
        return service.getCommentsByPost(postId);
    }

    // 3. Dar Like a un Post
    @PostMapping("/likes")
    public Mono<Like> giveLike(@RequestBody Like like) {
        return service.addLike(like);
    }

    // 4. Obtener la cantidad total de likes de un Post
    @GetMapping("/likes/count/{postId}")
    public Mono<Long> getLikeCount(@PathVariable Integer postId) {
        return service.getLikeCount(postId);
    }

    // 5. Quitar Like (Unlike)
    @DeleteMapping("/likes/{postId}/{username}")
    public Mono<Void> removeLike(@PathVariable Integer postId, @PathVariable String username) {
        return service.removeLike(postId, username);
    }
}