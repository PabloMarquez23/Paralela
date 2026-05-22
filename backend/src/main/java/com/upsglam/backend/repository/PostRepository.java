package com.upsglam.backend.repository;

import com.upsglam.backend.model.Post;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PostRepository extends ReactiveCrudRepository<Post, Integer> {
    // Al heredar de aquí, ya tenemos findByAll (para el feed) y save (para publicar) de forma no bloqueante.
}