package com.demo.health;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/health")
public class HealthController {

    private final ReadinessService readinessService;

    public HealthController(ReadinessService readinessService) {
        this.readinessService = readinessService;
    }

    @GetMapping("/live")
    public ResponseEntity<Map<String, Object>> liveness() {
        return ResponseEntity.ok(Map.of("status", "UP"));
    }

    @GetMapping("/ready")
    public ResponseEntity<Map<String, Object>> readiness() {
        if (readinessService.isReady()) {
            return ResponseEntity.ok(Map.of(
                    "status", "UP",
                    "startupTimeMs", readinessService.getStartupTimeMs()
            ));
        } else {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "DOWN"));
        }
    }
}
