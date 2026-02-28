package com.demo.health;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/health")
@Produces(MediaType.APPLICATION_JSON)
public class HealthController {

    @Inject
    ReadinessService readinessService;

    @GET
    @Path("/live")
    public Response liveness() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/ready")
    public Response readiness() {
        if (readinessService.isReady()) {
            return Response.ok(Map.of(
                    "status", "UP",
                    "startupTimeMs", readinessService.getStartupTimeMs()
            )).build();
        } else {
            return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                    .entity(Map.of("status", "DOWN"))
                    .build();
        }
    }
}
