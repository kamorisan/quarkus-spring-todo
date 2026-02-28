# Multi-stage build for Quarkus JVM
# ========================================
# Stage 1: Build the application
# ========================================
FROM registry.access.redhat.com/ubi9/openjdk-21:1.18 AS builder

# Install git
USER root
RUN microdnf install -y git && microdnf clean all

# Clone repository
WORKDIR /build
ARG GIT_REPO=https://github.com/kamorisan/quarkus-spring-todo.git
ARG GIT_BRANCH=main
RUN git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} .

# Build application
WORKDIR /build/quarkus-todo
RUN mvn package -DskipTests

# ========================================
# Stage 2: Create runtime image
# ========================================
FROM registry.access.redhat.com/ubi9/openjdk-21-runtime:1.18

# Copy the application
WORKDIR /deployments
COPY --from=builder /build/quarkus-todo/target/quarkus-app/lib/ /deployments/lib/
COPY --from=builder /build/quarkus-todo/target/quarkus-app/*.jar /deployments/
COPY --from=builder /build/quarkus-todo/target/quarkus-app/app/ /deployments/app/
COPY --from=builder /build/quarkus-todo/target/quarkus-app/quarkus/ /deployments/quarkus/

# Set permissions for OpenShift
USER root
RUN chown -R 185:0 /deployments && \
    chmod -R g=u /deployments

# Run as non-root user
USER 185

# Expose port
EXPOSE 8080

# Set environment variables
ENV JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Dquarkus.http.port=8080 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

# Run the application
ENTRYPOINT ["java", "-jar", "/deployments/quarkus-run.jar"]
