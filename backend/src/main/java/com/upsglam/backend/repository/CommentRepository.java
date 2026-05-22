package com.upsglam.backend.repository;

import com.upsglam.backend.model.Comment;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

@Repository
public interface CommentRepository extends ReactiveCrudRepository<Comment, Integer> {
    // Busca todos los comentarios asociados a un post específico de forma reactiva
    Flux<Comment> findByPostId(Integer postId);
}