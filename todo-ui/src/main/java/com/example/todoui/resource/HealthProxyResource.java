package com.example.todoui.resource;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Path("/api/backend")
@Produces(MediaType.APPLICATION_JSON)
public class HealthProxyResource {

    @ConfigProperty(name = "quarkus.rest-client.\"com.example.todoui.client.TodoClient\".url")
    String backendUrl;

    @ConfigProperty(name = "backend.type", defaultValue = "quarkus")
    String backendType;

    @GET
    @Path("/health")
    public Response getBackendHealth() {
        try {
            String healthEndpoint = "quarkus".equalsIgnoreCase(backendType)
                ? "/q/health/ready"
                : "/actuator/health/readiness";

            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(backendUrl + healthEndpoint))
                .GET()
                .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            return Response.status(response.statusCode())
                .entity(response.body())
                .build();
        } catch (Exception e) {
            return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                .entity("{\"status\":\"DOWN\",\"error\":\"" + e.getMessage() + "\"}")
                .build();
        }
    }

    @GET
    @Path("/info")
    public Response getBackendInfo() {
        return Response.ok()
            .entity("{\"url\":\"" + backendUrl + "\",\"type\":\"" + backendType + "\"}")
            .build();
    }
}
