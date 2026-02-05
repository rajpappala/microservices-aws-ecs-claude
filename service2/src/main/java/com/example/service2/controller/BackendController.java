package com.example.service2.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class BackendController {

    @GetMapping("/endpoint1")
    public ResponseEntity<Map<String, Object>> endpoint1() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "Service 2");
        response.put("endpoint", "/api/endpoint1");
        response.put("message", "Hello from Service 2 - Endpoint 1");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("data", Map.of(
            "id", 1,
            "name", "Sample Data from Endpoint 1",
            "value", "This is response data from Service 2"
        ));
        return ResponseEntity.ok(response);
    }

    @GetMapping("/endpoint2")
    public ResponseEntity<Map<String, Object>> endpoint2() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "Service 2");
        response.put("endpoint", "/api/endpoint2");
        response.put("message", "Hello from Service 2 - Endpoint 2");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("data", Map.of(
            "id", 2,
            "name", "Sample Data from Endpoint 2",
            "value", "Different response data from Service 2",
            "status", "active"
        ));
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Service 2 - Backend");
        return ResponseEntity.ok(response);
    }
}
