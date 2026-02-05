package com.example.service1.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
public class Service2Client {

    private final WebClient webClient;

    public Service2Client(WebClient.Builder webClientBuilder,
                          @Value("${service2.url}") String service2Url) {
        this.webClient = webClientBuilder.baseUrl(service2Url).build();
    }

    public String callEndpoint1() {
        try {
            return webClient.get()
                    .uri("/api/endpoint1")
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();
        } catch (Exception e) {
            return "Error calling Service 2 endpoint1: " + e.getMessage();
        }
    }

    public String callEndpoint2() {
        try {
            return webClient.get()
                    .uri("/api/endpoint2")
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();
        } catch (Exception e) {
            return "Error calling Service 2 endpoint2: " + e.getMessage();
        }
    }
}
