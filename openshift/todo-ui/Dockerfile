# Multi-stage build for Todo UI (Quarkus JVM)
# Stage 1: Build the application from GitHub source
FROM registry.access.redhat.com/ubi9/openjdk-21:1.18 AS builder

# Build arguments
ARG GIT_REPO=https://github.com/kamorisan/quarkus-spring-todo.git
ARG GIT_BRANCH=main

# Set working directory
WORKDIR /build

# Install git and clone repository
USER root
RUN microdnf install -y git && microdnf clean all

# Clone repository
RUN git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} .

# Change ownership to user 185
RUN chown -R 185:0 /build && chmod -R g+rwX /build

# Build the application
USER 185
WORKDIR /build/todo-ui
RUN mvn package -DskipTests

# Stage 2: Runtime image
FROM registry.access.redhat.com/ubi9/openjdk-21-runtime:1.18

# Copy the built application
COPY --from=builder /build/todo-ui/target/quarkus-app/lib/ /deployments/lib/
COPY --from=builder /build/todo-ui/target/quarkus-app/*.jar /deployments/
COPY --from=builder /build/todo-ui/target/quarkus-app/app/ /deployments/app/
COPY --from=builder /build/todo-ui/target/quarkus-app/quarkus/ /deployments/quarkus/

# Set environment variables
ENV LANGUAGE='en_US:en'

# Run as non-root user
USER 185

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/q/health/ready || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "/deployments/quarkus-run.jar"]
