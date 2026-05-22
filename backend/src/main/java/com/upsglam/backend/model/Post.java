package com.upsglam.backend.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table("posts")
public class Post {

    @Id
    private Integer id;
    private String username;
    private String description;
    private String originalImageUrl;
    private String processedImageUrl;
    private String filterUsed;
    private LocalDateTime createdAt;
}