package com.upsglam.backend.controller;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.repository.GpuMetricRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.codec.multipart.FilePart;
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

    private final WebClient webClient = WebClient.create("http://localhost:5000");

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
            @RequestPart("filter") String filter,      // 🎯 Regresa a RequestPart para recibir bloques Multipart explícitos
            @RequestPart("mask_size") String maskSize   // 🎯 Regresa a RequestPart para recibir bloques Multipart explícitos
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

                    // Construcción del cuerpo hacia Flask
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

                    return webClient.post()
                            .uri("/api/pycuda/apply-filter")
                            .contentType(MediaType.MULTIPART_FORM_DATA)
                            .body(BodyInserters.fromMultipartData(body))
                            .retrieve()
                            .bodyToMono(Map.class)
                            .flatMap(response -> {
                                GpuMetric metric = new GpuMetric();
                                metric.setId(UUID.randomUUID());
                                metric.setNew(true);
                                metric.setOriginalImageUrl(filePart.filename());
                                metric.setProcessedImageUrl(response.get("processedPath").toString());
                                metric.setImageWidth(((Number) response.get("imageWidth")).intValue());
                                metric.setImageHeight(((Number) response.get("imageHeight")).intValue());
                                metric.setBlockDimX(((Number) response.get("blockDimX")).intValue());
                                metric.setBlockDimY(((Number) response.get("blockDimY")).intValue());
                                metric.setGridDimX(((Number) response.get("gridDimX")).intValue());
                                metric.setGridDimY(((Number) response.get("gridDimY")).intValue());
                                metric.setTotalThreadsLaunched(((Number) response.get("totalThreadsLaunched")).longValue());
                                metric.setKernelTimeMs(((Number) response.get("kernelTimeMs")).doubleValue());
                                metric.setStatus(response.get("status").toString());
                                metric.setCreatedAt(LocalDateTime.now());

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
    }
}