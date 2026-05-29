package com.upsglam.backend.service;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.repository.GpuMetricRepository;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Service
public class CudaProcessingService {

    private final WebClient webClient;
    private final GpuMetricRepository metricRepository;

    public CudaProcessingService(WebClient webClient, GpuMetricRepository metricRepository) {
        this.webClient = webClient;
        this.metricRepository = metricRepository;
    }

    public Mono<GpuMetric> sendToCuda(String filterType, String imagePath) {
        Map<String, String> requestBody = Map.of(
            "filter", filterType,
            "imagePath", imagePath,
            "mask_size", "AUTO" // 🎯 Mapeo automático
        );

        return webClient.post()
                .uri("/process")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .flatMap(response -> {
                    GpuMetric metric = new GpuMetric();
                    metric.setId(UUID.randomUUID());
                    metric.setNewEntry(true);
                    
                    metric.setOriginalImageUrl(imagePath);
                    metric.setProcessedImageUrl(imagePath.replace(".jpg", "_gpu.jpg").replace(".jpeg", "_gpu.jpeg").replace(".png", "_gpu.png"));
                    
                    String imageSizeStr = (String) response.getOrDefault("imageSize", "1024x1024");
                    String[] dimensions = imageSizeStr.split("x");
                    int width = Integer.parseInt(dimensions[0]);
                    int height = Integer.parseInt(dimensions[1]);
                    
                    metric.setImageWidth(width);
                    metric.setImageHeight(height);
                    metric.setBlockDimX(16);
                    metric.setBlockDimY(16);
                    
                    metric.setGridDimX((int) Math.ceil(width / 16.0));
                    metric.setGridDimY((int) Math.ceil(height / 16.0));
                    metric.setTotalThreadsLaunched((long) metric.getGridDimX() * metric.getGridDimY() * 256);
                    
                    Object executionTime = response.get("executionTimeMs");
                    if (executionTime instanceof Number) {
                        metric.setKernelTimeMs(((Number) executionTime).doubleValue());
                    } else {
                        metric.setKernelTimeMs(0.0);
                    }
                    
                    metric.setStatus("COMPLETED"); 
                    metric.setCreatedAt(LocalDateTime.now());
                    
                    return metricRepository.save(metric);
                });
    }
}