package com.upsglam.backend.controller;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.service.CudaProcessingService;
import com.upsglam.backend.service.GpuMetricService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
public class GpuMetricController {

    private final GpuMetricService metricService;
    private final CudaProcessingService cudaService;

    public GpuMetricController(GpuMetricService metricService, CudaProcessingService cudaService) {
        this.metricService = metricService;
        this.cudaService = cudaService;
    }

    @GetMapping
    public Flux<GpuMetric> getAllMetrics() {
        return metricService.getAllMetrics();
    }

    // --- ENDPOINT PUENTE LIMPIO Y DIRECTO ---
    @PostMapping("/process-image")
    public Mono<GpuMetric> processImage(@RequestParam String filter, @RequestParam String path) {
        // Toda la lógica de guardado y mapeo de campos se maneja de forma asíncrona en el servicio
        return cudaService.sendToCuda(filter, path);
    }
}