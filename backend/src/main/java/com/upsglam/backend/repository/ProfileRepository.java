package com.upsglam.backend.repository;

import com.upsglam.backend.model.Profile;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;
import java.util.UUID;

@Repository
public interface ProfileRepository extends ReactiveCrudRepository<Profile, UUID> {

    @Modifying
    @Query("UPDATE public.profiles SET bio = :bio, updated_at = NOW() WHERE id = :userId")
    Mono<Void> updateBio(UUID userId, String bio);

    @Query("SELECT EXISTS(SELECT 1 FROM public.follows WHERE follower_id = :followerId AND following_id = :followingId)")
    Mono<Boolean> existsFollow(UUID followerId, UUID followingId);

    @Modifying
    @Query("INSERT INTO public.follows (follower_id, following_id) VALUES (:followerId, :followingId)")
    Mono<Void> addFollow(UUID followerId, UUID followingId);

    @Modifying
    @Query("INSERT INTO public.notifications (user_id, source_user_id, type) VALUES (:targetUserId, :sourceUserId, 'FOLLOW')")
    Mono<Void> createFollowNotification(UUID targetUserId, UUID sourceUserId);

    @Modifying
    @Query("UPDATE public.profiles SET avatar_url = :avatarUrl, updated_at = NOW() WHERE id = :userId")
    Mono<Void> updateAvatarUrl(UUID userId, String avatarUrl);
}