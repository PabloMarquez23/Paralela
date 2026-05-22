package com.upsglam.backend.service;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.repository.GpuMetricRepository;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
public class GpuMetricService {

    private final GpuMetricRepository repository;

    // Inyección por constructor (Buena práctica)
    public GpuMetricService(GpuMetricRepository repository) {
        this.repository = repository;
    }

    // Guardar una nueva métrica de procesamiento GPU
    public Mono<GpuMetric> saveMetric(GpuMetric metric) {
        if (metric.getCreatedAt() == null) {
            metric.setCreatedAt(LocalDateTime.now());
        }
        return repository.save(metric);
    }

    // Obtener todo el historial de procesamiento de forma reactiva
    public Flux<GpuMetric> getAllMetrics() {
        return repository.findAll();
    }
}