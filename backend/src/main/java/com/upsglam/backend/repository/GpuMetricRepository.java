package com.upsglam.backend.repository;

import com.upsglam.backend.model.GpuMetric;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface GpuMetricRepository extends ReactiveCrudRepository<GpuMetric, UUID> {
    // Cambiamos el tipo de ID de Integer a UUID para que machee perfectamente 
    // con la clave primaria que acabamos de ver registrada en Supabase Cloud.
}