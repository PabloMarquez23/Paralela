package com.upsglam.backend.controller;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.repository.GpuMetricRepository;
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
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
public class GpuMetricController {

    @Autowired
    private GpuMetricRepository repository;

    @Autowired
    private DatabaseClient databaseClient; 

    // Buffer de 10MB para que no explote con imágenes grandes de la cámara
    private final WebClient webClient = WebClient.builder()
            .baseUrl("http://localhost:5000")
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
            .build();

    @GetMapping("/available-filters")
    public Mono<Map> getAvailableFilters() {
        return webClient.get()
                .uri("/api/pycuda/filters")
                .retrieve()
                .bodyToMono(Map.class);
    }

    @PostMapping(value = "/process-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.IMAGE_JPEG_VALUE)
    public Mono<byte[]> processImage(
            @RequestPart("image") FilePart filePart,
            @RequestPart("filter") String filter,      
            @RequestPart("mask_size") String maskSize,
            @RequestPart(value = "userId", required = false) String userId // Viene opcional desde la app
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
                        public String getFilename() {
                            return filePart.filename();
                        }
                    };
                    
                    body.add("image", resource);
                    body.add("filter", filter);
                    body.add("mask_size", maskSize);

                    // 1. Mandar a procesar a la GPU (Flask)
                    return webClient.post()
                            .uri("/api/pycuda/apply-filter")
                            .contentType(MediaType.MULTIPART_FORM_DATA)
                            .body(BodyInserters.fromMultipartData(body))
                            .retrieve()
                            .bodyToMono(Map.class)
                            .flatMap(response -> {
                                
                                // 2. Buscar el ID real del filtro en base a su kernel_name
                                return databaseClient.sql("SELECT id FROM public.filters WHERE kernel_name = :kernelName OR name = :kernelName LIMIT 1")
                                        .bind("kernelName", filter)
                                        .fetch()
                                        .first()
                                        .map(row -> UUID.fromString(row.get("id").toString()))
                                        .defaultIfEmpty(UUID.randomUUID()) 
                                        .flatMap(resolvedFilterId -> {
                                            
                                            GpuMetric metric = new GpuMetric();
                                            metric.setId(UUID.randomUUID());
                                            metric.setNew(true);
                                            
                                            // 🎯 SALVADAVIDAS ANTI-BOLITA: Si Flutter no envía el usuario, le clavamos tu ID de pruebas
                                            if (userId != null && !userId.isEmpty()) {
                                                metric.setUserId(UUID.fromString(userId));
                                            } else {
                                                metric.setUserId(UUID.fromString("50c18c05-a920-452b-9e85-f9ae9c4584b2")); 
                                            }
                                            
                                            metric.setFilterId(resolvedFilterId);
                                            metric.setOriginalImageUrl(filePart.filename());
                                            metric.setProcessedImageUrl(response.get("processedPath").toString());
                                            
                                            // Conversiones robustas para evitar errores de mapeo en PostgreSQL
                                            metric.setImageWidth(parseInteger(response.get("imageWidth")));
                                            metric.setImageHeight(parseInteger(response.get("imageHeight")));
                                            metric.setBlockDimX(parseInteger(response.get("blockDimX")));
                                            metric.setBlockDimY(parseInteger(response.get("blockDimY")));
                                            metric.setGridDimX(parseInteger(response.get("gridDimX")));
                                            metric.setGridDimY(parseInteger(response.get("gridDimY")));
                                            metric.setTotalThreadsLaunched(parseLong(response.get("totalThreadsLaunched")));
                                            metric.setKernelTimeMs(parseDouble(response.get("kernelTimeMs")));
                                            
                                            metric.setStatus(response.get("status").toString());
                                            metric.setCreatedAt(LocalDateTime.now());

                                            // 3. Guardar la telemetría y responder los bytes a la App Móvil
                                            return repository.save(metric)
                                                    .flatMap(saved -> webClient.get()
                                                            .uri(uriBuilder -> uriBuilder
                                                                    .path("/api/pycuda/download")
                                                                    .queryParam("path", saved.getProcessedImageUrl())
                                                                    .build())
                                                            .retrieve()
                                                            .bodyToMono(byte[].class));
                                        });
                            });
                });
    }

    // Parsers de seguridad para evitar ClassCastExceptions asíncronas
    private Integer parseInteger(Object obj) {
        if (obj == null) return 0;
        return (obj instanceof Number) ? ((Number) obj).intValue() : Integer.parseInt(obj.toString());
    }

    private Long parseLong(Object obj) {
        if (obj == null) return 0L;
        return (obj instanceof Number) ? ((Number) obj).longValue() : Long.parseLong(obj.toString());
    }

    private Double parseDouble(Object obj) {
        if (obj == null) return 0.0;
        return (obj instanceof Number) ? ((Number) obj).doubleValue() : Double.parseDouble(obj.toString());
    }
}