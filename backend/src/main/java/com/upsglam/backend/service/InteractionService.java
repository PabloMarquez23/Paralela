package com.upsglam.backend.service;

import com.upsglam.backend.model.Comment;
import com.upsglam.backend.model.Like;
import com.upsglam.backend.repository.CommentRepository;
import com.upsglam.backend.repository.LikeRepository;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
public class InteractionService {

    private final CommentRepository commentRepository;
    private final LikeRepository likeRepository;

    public InteractionService(CommentRepository commentRepository, LikeRepository likeRepository) {
        this.commentRepository = commentRepository;
        this.likeRepository = likeRepository;
    }

    // --- COMENTARIOS ---
    public Mono<Comment> addComment(Comment comment) {
        comment.setCreatedAt(LocalDateTime.now());
        return commentRepository.save(comment);
    }

    public Flux<Comment> getCommentsByPost(Integer postId) {
        return commentRepository.findByPostId(postId);
    }

    // --- LIKES ---
    public Mono<Like> addLike(Like like) {
        like.setCreatedAt(LocalDateTime.now());
        return likeRepository.save(like);
    }

    public Mono<Void> removeLike(Integer postId, String username) {
        return likeRepository.deleteByPostIdAndUsername(postId, username);
    }

    public Mono<Long> getLikeCount(Integer postId) {
        return likeRepository.countByPostId(postId);
    }
}