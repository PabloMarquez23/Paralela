package com.upsglam.backend.repository;

import com.upsglam.backend.model.Post;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import java.util.UUID;

@Repository
public interface PostRepository extends ReactiveCrudRepository<Post, UUID> {

    // 🎯 QUERY: Trae las publicaciones combinadas con el nombre de usuario para el Feed Global
    @Query("SELECT p.*, pr.username FROM public.posts p " +
           "JOIN public.profiles pr ON p.user_id = pr.id " +
           "ORDER BY p.created_at DESC")
    Flux<Post> findAllWithUsername();

    // 🎯 QUERY: Trae las publicaciones de un solo alumno para su vista de Perfil
    @Query("SELECT p.*, pr.username FROM public.posts p " +
           "JOIN public.profiles pr ON p.user_id = pr.id " +
           "WHERE p.user_id = :userId " +
           "ORDER BY p.created_at DESC")
    Flux<Post> findByUserIdWithUsername(UUID userId);
}