package com.upsglam.backend.service;

import com.upsglam.backend.model.Post;
import com.upsglam.backend.repository.PostRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class PostService {

    private final PostRepository repository;

    // Inyección obligatoria consumida por tu PostController
    public PostService(PostRepository repository) {
        this.repository = repository;
    }

    /**
     * 🎯 Registra una nueva publicación forzando la persistencia directa en Supabase Cloud.
     * La anotación @Transactional asegura que se complete el COMMIT físico en internet.
     */
    @Transactional
    public Mono<Post> createPost(Post post) {
        // Generamos el ID desde Java para evitar conflictos de sincronización asíncrona con PostgreSQL
        if (post.getId() == null) {
            post.setId(UUID.randomUUID());
        }
        
        post.setCreatedAt(LocalDateTime.now());
        post.setNewEntry(true); // Fuerza a R2DBC a interpretar la operación como un INSERT SQL explícito

        return repository.save(post);
    }

    /**
     * 🎯 Consume la consulta relacional con el JOIN para retornar todo el Feed con usernames.
     */
    public Flux<Post> getFeed() {
        return repository.findAllWithUsername();
    }
}