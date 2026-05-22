package com.upsglam.backend.service;

import com.upsglam.backend.model.Post;
import com.upsglam.backend.repository.PostRepository;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
public class PostService {

    private final PostRepository repository;

    public PostService(PostRepository repository) {
        this.repository = repository;
    }

    // Guardar publicación de forma reactiva
    public Mono<Post> createPost(Post post) {
        if (post.getCreatedAt() == null) {
            post.setCreatedAt(LocalDateTime.now());
        }
        return repository.save(post);
    }

    // Obtener todas las publicaciones para el feed de Flutter
    public Flux<Post> getFeed() {
        return repository.findAll();
    }
}