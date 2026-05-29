package com.upsglam.backend.controller;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.service.GpuMetricService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
public class GpuMetricController {

    @Autowired
    private GpuMetricService metricService; 

    @Autowired
    private DatabaseClient databaseClient; 

    private final WebClient webClient = WebClient.builder()
            .baseUrl("http://localhost:5000") // Flask
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
            .build();

    @GetMapping("/history")
    public Flux<GpuMetric> getMetricsHistory() {
        return metricService.getAllMetrics();
    }

    @PostMapping(value = "/process-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<Map<String, Object>> processImage(
            @RequestPart("image") FilePart filePart,
            @RequestPart("filter") String filter,      
            @RequestPart(value = "userId", required = false) String userId 
    ) {
        return filePart.content()
                .map(dataBuffer -> {
                    byte[] bytes = new byte[dataBuffer.readableByteCount()];
                    dataBuffer.read(bytes);
                    return bytes;
                })
                .collectList()
                .flatMap(list -> {
                    int totalSize = list.stream().mapToInt(b -> b.length).sum();
                    byte[] allBytes = new byte[totalSize];
                    int offset = 0;
                    for (byte[] b : list) {
                        System.arraycopy(b, 0, allBytes, offset, b.length);
                        offset += b.length;
                    }

                    MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
                    ByteArrayResource resource = new ByteArrayResource(allBytes) {
                        @Override
                        public String getFilename() { return filePart.filename(); }
                    };
                    
                    body.add("image", resource);
                    body.add("filter", filter);
                    body.add("mask_size", "AUTO");

                    return webClient.post()
                            .uri("/api/pycuda/apply-filter")
                            .contentType(MediaType.MULTIPART_FORM_DATA)
                            .body(BodyInserters.fromMultipartData(body))
                            .retrieve()
                            .bodyToMono(Map.class)
                            .flatMap(response -> {
                                // Buscamos relacionalmente el UUID del filtro usando el ID técnico
                                return databaseClient.sql("SELECT id FROM public.filters WHERE kernel_name = :kernelName OR name = :kernelName LIMIT 1")
                                        .bind("kernelName", filter)
                                        .fetch()
                                        .first()
                                        .map(row -> UUID.fromString(row.get("id").toString()))
                                        .defaultIfEmpty(UUID.randomUUID()) 
                                        .flatMap(resolvedFilterId -> {
                                            GpuMetric metric = new GpuMetric();
                                            metric.setId(UUID.randomUUID());
                                            metric.setNewEntry(true); 
                                            
                                            // Validamos que el ID del estudiante sea correcto
                                            metric.setUserId(userId != null && !userId.equals("null") && !userId.isEmpty() 
                                                ? UUID.fromString(userId) 
                                                : UUID.fromString("50c18c05-a920-452b-9e85-f9ae9c4584b2"));
                                            
                                            metric.setFilterId(resolvedFilterId);
                                            metric.setOriginalImageUrl("original-images/" + filePart.filename());
                                            metric.setProcessedImageUrl(response.get("processedPath").toString());
                                            
                                            // 🎯 EXTRACCIÓN CORREGIDA Y PURA DE TELEMETRÍA DESDE FLASK (Evita los ceros)
                                            int width = parseInteger(response.get("imageWidth"));
                                            int height = parseInteger(response.get("imageHeight"));
                                            
                                            // Si Flask no mandó las dimensiones del grid, las recalculamos aquí para asegurar datos reales
                                            int gX = response.containsKey("gridDimX") ? parseInteger(response.get("gridDimX")) : (int)((width + 15) / 16);
                                            int gY = response.containsKey("gridDimY") ? parseInteger(response.get("gridDimY")) : (int)((height + 15) / 16);
                                            long threads = (long) gX * 16 * gY * 16;

                                            metric.setImageWidth(width);
                                            metric.setImageHeight(height);
                                            metric.setBlockDimX(16); // Bloques fijos de 16x16 definidos en el laboratorio
                                            metric.setBlockDimY(16);
                                            metric.setGridDimX(gX);
                                            metric.setGridDimY(gY);
                                            metric.setTotalThreadsLaunched(threads); // 🎯 Hilos calculados de hardware puro
                                            metric.setKernelTimeMs(parseDouble(response.get("kernelTimeMs")));
                                            metric.setStatus("COMPLETED");
                                            metric.setCreatedAt(LocalDateTime.now());

                                            return metricService.saveMetric(metric)
                                                    .flatMap(saved -> webClient.get()
                                                            .uri(uriBuilder -> uriBuilder
                                                                    .path("/api/pycuda/download")
                                                                    .queryParam("path", saved.getProcessedImageUrl())
                                                                    .build())
                                                            .retrieve()
                                                            .bodyToMono(byte[].class)
                                                            .map(bytes -> Map.of(
                                                                "imageBytes", java.util.Base64.getEncoder().encodeToString(bytes),
                                                                "kernelTimeMs", metric.getKernelTimeMs(),
                                                                "appliedMask", response.get("appliedMask").toString()
                                                            )));
                                        });
                            });
                });
    }

    private Integer parseInteger(Object obj) { return obj == null ? 0 : (obj instanceof Number) ? ((Number) obj).intValue() : Integer.parseInt(obj.toString()); }
    private Long parseLong(Object obj) { return obj == null ? 0L : (obj instanceof Number) ? ((Number) obj).longValue() : Long.parseLong(obj.toString()); }
    private Double parseDouble(Object obj) { return obj == null ? 0.0 : (obj instanceof Number) ? ((Number) obj).doubleValue() : Double.parseDouble(obj.toString()); }
}