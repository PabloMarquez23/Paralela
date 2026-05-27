package com.upsglam.backend.repository;

import com.upsglam.backend.model.GpuMetric;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface GpuMetricRepository extends ReactiveCrudRepository<GpuMetric, UUID> {
    // Repositorio reactivo acoplado a UUID para telemetría paralela de PostgreSQL
}