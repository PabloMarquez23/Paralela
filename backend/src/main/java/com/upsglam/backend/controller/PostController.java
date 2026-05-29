package com.upsglam.backend.controller;

import com.upsglam.backend.model.Post;
import com.upsglam.backend.service.PostService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*")
public class PostController {

    private final PostService service;

    public PostController(PostService service) {
        this.service = service;
    }

    @PostMapping
    public Mono<Post> createPost(@RequestBody Post post) {
        return service.createPost(post);
    }

    @GetMapping
    public Flux<com.upsglam.backend.dto.PostFeedDto> getFeed() {
        return service.getFeed();
    }
}