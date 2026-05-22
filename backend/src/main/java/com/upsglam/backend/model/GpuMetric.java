package com.upsglam.backend.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;
import org.springframework.data.relational.core.mapping.Column;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(value = "processing_history", schema = "public") // 🎯 Forzamos el esquema público de Supabase
public class GpuMetric {
    
    @Id
    private UUID id; // Manejado como UUID nativo cloud
    
    @Column("user_id")
    private UUID userId;
    
    @Column("filter_id")
    private UUID filterId;
    
    @Column("original_image_url")
    private String originalImageUrl;
    
    @Column("processed_image_url")
    private String processedImageUrl;
    
    @Column("image_width")
    private Integer imageWidth;
    
    @Column("image_height")
    private Integer imageHeight;
    
    @Column("block_dim_x")
    private Integer blockDimX;
    
    @Column("block_dim_y")
    private Integer blockDimY;
    
    @Column("grid_dim_x")
    private Integer gridDimX;
    
    @Column("grid_dim_y")
    private Integer gridDimY;
    
    @Column("total_threads_launched")
    private Long totalThreadsLaunched;
    
    @Column("kernel_time_ms")
    private Double kernelTimeMs;
    
    private String status;
    private LocalDateTime createdAt;
}