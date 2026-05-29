package com.upsglam.backend.service;

import com.upsglam.backend.model.GpuMetric;
import com.upsglam.backend.repository.GpuMetricRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.time.LocalDateTime;

@Service
public class GpuMetricService {

    private final GpuMetricRepository repository;

    public GpuMetricService(GpuMetricRepository repository) {
        this.repository = repository;
    }

    /**
     * 🎯 Lógica transaccional para persistir las métricas de hardware de la GeForce.
     */
    @Transactional
    public Mono<GpuMetric> saveMetric(GpuMetric metric) {
        if (metric.getCreatedAt() == null) {
            metric.setCreatedAt(LocalDateTime.now());
        }
        metric.setNewEntry(true); // 🔥 Blindaje R2DBC: Asegura el INSERT puro en Supabase
        return repository.save(metric);
    }

    /**
     * 🎯 Recupera el historial dinámico consumiendo la consulta relacional del repositorio.
     */
    public Flux<GpuMetric> getAllMetrics() {
        return repository.findAllWithFilterNames();
    }
}