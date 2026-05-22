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
@Table("likes")
public class Like {
    @Id
    private Integer id;
    private Integer postId;
    private String username;
    private LocalDateTime createdAt;
}