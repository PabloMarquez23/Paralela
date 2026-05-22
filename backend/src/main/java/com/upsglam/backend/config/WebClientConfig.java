package com.upsglam.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {

    @Bean
    public WebClient webClient() {
        // Usamos WebClient.builder() directamente de la librería para evitar que Spring falle buscándolo
        return WebClient.builder()
                .baseUrl("http://localhost:5000")
                .build();
    }
}