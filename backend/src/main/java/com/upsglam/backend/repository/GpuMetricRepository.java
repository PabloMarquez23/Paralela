package com.upsglam.backend.repository;

import com.upsglam.backend.model.GpuMetric;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import java.util.UUID;

@Repository
public interface GpuMetricRepository extends ReactiveCrudRepository<GpuMetric, UUID> {

    /**
     * 🎯 Query nativo relacional para extraer el historial unificado con el nombre del filtro.
     */
    @Query("SELECT ph.*, f.name as filter_name " +
           "FROM public.processing_history ph " +
           "LEFT JOIN public.filters f ON ph.filter_id = f.id " +
           "ORDER BY ph.created_at DESC")
    Flux<GpuMetric> findAllWithFilterNames();
}