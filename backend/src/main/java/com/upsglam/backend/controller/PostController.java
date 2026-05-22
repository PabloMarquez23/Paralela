package com.upsglam.backend.controller;

import com.upsglam.backend.model.Post;
import com.upsglam.backend.service.PostService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*") // Clave para evitar problemas de CORS con la app móvil
public class PostController {

    private final PostService service;

    public PostController(PostService service) {
        this.service = service;
    }

    // Endpoint para que Flutter cree un nuevo post en el feed
    @PostMapping
    public Mono<Post> createPost(@RequestBody Post post) {
        return service.createPost(post);
    }

    // Endpoint para que Flutter recupere el feed general
    @GetMapping
    public Flux<Post> getFeed() {
        return service.getFeed();
    }
}