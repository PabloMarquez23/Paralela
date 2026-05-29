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

    private final PostRepository postRepository;

    public PostService(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    public Flux<com.upsglam.backend.dto.PostFeedDto> getFeed() {
    return postRepository.findAllPostsWithUsernames();
    }

    @Transactional
    public Mono<Post> createPost(Post post) {
        if (post.getId() == null) {
            post.setId(UUID.randomUUID());
        }
        if (post.getCreatedAt() == null) {
            post.setCreatedAt(LocalDateTime.now());
        }
        post.setNewEntry(true); 
        return postRepository.save(post);
    }
}