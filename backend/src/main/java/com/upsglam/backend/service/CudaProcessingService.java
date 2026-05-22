package com.upsglam.backend.service;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.repository.GpuMetricRepository;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Map;

@Service
public class CudaProcessingService {

    private final WebClient webClient;
    private final GpuMetricRepository metricRepository;

    public CudaProcessingService(WebClient webClient, GpuMetricRepository metricRepository) {
        this.webClient = webClient;
        this.metricRepository = metricRepository;
    }

    public Mono<GpuMetric> sendToCuda(String filterType, String imagePath) {
        // 1. JSON para el script de Python
        Map<String, String> requestBody = Map.of(
            "filter", filterType,
            "imagePath", imagePath
        );

        // 2. HTTP POST no bloqueante al microservicio de Python (/process)
        return webClient.post()
                .uri("/process")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .flatMap(response -> {
                    GpuMetric metric = new GpuMetric();
                    
                    // Mapeo del esquema real de la base de datos cloud
                    metric.setOriginalImageUrl(imagePath);
                    metric.setProcessedImageUrl(imagePath.replace(".jpg", "_gpu.jpg").replace(".jpeg", "_gpu.jpeg").replace(".png", "_gpu.png"));
                    
                    // Parseo seguro del tamaño devuelto por la GPU
                    String imageSizeStr = (String) response.getOrDefault("imageSize", "1024x1024");
                    String[] dimensions = imageSizeStr.split("x");
                    metric.setImageWidth(Integer.parseInt(dimensions[0]));
                    metric.setImageHeight(Integer.parseInt(dimensions[1]));
                    
                    // Configuración del bloque CUDA de tu hardware
                    metric.setBlockDimX(16);
                    metric.setBlockDimY(16);
                    
                    // Cálculo dinámico de la Grilla para el reporte de la tesis
                    metric.setGridDimX((int) Math.ceil(metric.getImageWidth() / 16.0));
                    metric.setGridDimY((int) Math.ceil(metric.getImageHeight() / 16.0));
                    metric.setTotalThreadsLaunched(256L);
                    
                    // Tiempo preciso de ejecución del Kernel devuelto por la GPU
                    Object executionTime = response.get("executionTimeMs");
                    if (executionTime instanceof Number) {
                        metric.setKernelTimeMs(((Number) executionTime).doubleValue());
                    } else {
                        metric.setKernelTimeMs(0.0);
                    }
                    
                    // 🎯 CORRECCIÓN CRÍTICA: Cambiado de 'SUCCESS' a 'COMPLETED' para pasar el CHECK del SQL
                    metric.setStatus("COMPLETED"); 
                    metric.setCreatedAt(LocalDateTime.now());
                    
                    // Campos de llaves foráneas se quedan en null de forma limpia en el test de Postman
                    metric.setUserId(null);
                    metric.setFilterId(null);
                    
                    // 3. Persistencia reactiva directa en Supabase Cloud
                    return metricRepository.save(metric);
                });
    }
}