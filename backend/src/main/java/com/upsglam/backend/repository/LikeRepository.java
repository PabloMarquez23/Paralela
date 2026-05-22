package com.upsglam.backend.repository;

import com.upsglam.backend.model.Like;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Repository
public interface LikeRepository extends ReactiveCrudRepository<Like, Integer> {
    // Cuenta cuántos likes tiene un post de forma no bloqueante
    Mono<Long> countByPostId(Integer postId);
    
    // Para cuando el usuario quiera quitar su like (Unliked)
    Mono<Void> deleteByPostIdAndUsername(Integer postId, String username);
}