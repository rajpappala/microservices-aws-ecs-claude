package com.example.service1.controller;

import com.example.service1.service.Service2Client;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class GatewayController {

    @Autowired
    private Service2Client service2Client;

    @GetMapping("/api1")
    public ResponseEntity<Map<String, Object>> api1() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "Service 1");
        response.put("endpoint", "/api/api1");
        response.put("message", "This is API1 from Service 1");

        // Call Service 2's endpoint1
        String service2Response = service2Client.callEndpoint1();
        response.put("service2_response", service2Response);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/api2")
    public ResponseEntity<Map<String, Object>> api2() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "Service 1");
        response.put("endpoint", "/api/api2");
        response.put("message", "This is API2 from Service 1");

        // Call Service 2's endpoint2
        String service2Response = service2Client.callEndpoint2();
        response.put("service2_response", service2Response);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Service 1 - API Gateway");
        return ResponseEntity.ok(response);
    }
}
