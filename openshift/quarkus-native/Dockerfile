# Multi-stage build for Quarkus Native Image
# ========================================
# Stage 1: Build the application
# ========================================
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3 AS builder

# Install build dependencies
RUN microdnf install -y tar gzip which gcc glibc-devel zlib-devel git findutils

# Install GraalVM
ENV GRAALVM_VERSION=21.0.2
ENV GRAALVM_HOME=/opt/graalvm
RUN curl -L https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz -o /tmp/graalvm.tar.gz && \
    mkdir -p /opt && \
    tar -xzf /tmp/graalvm.tar.gz -C /opt && \
    mv /opt/graalvm-community-openjdk-* ${GRAALVM_HOME} && \
    rm /tmp/graalvm.tar.gz

ENV PATH="${GRAALVM_HOME}/bin:${PATH}"
ENV JAVA_HOME="${GRAALVM_HOME}"

# Install Maven
ENV MAVEN_VERSION=3.9.6
RUN curl -L https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/maven.tar.gz && \
    tar -xzf /tmp/maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/local/bin/mvn && \
    rm /tmp/maven.tar.gz

# Clone repository
WORKDIR /build
ARG GIT_REPO=https://github.com/kamorisan/quarkus-spring-todo.git
ARG GIT_BRANCH=main
RUN git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} .

# Build native image
WORKDIR /build/quarkus-todo
RUN mvn package -Pnative -DskipTests \
    -Djava.home=${GRAALVM_HOME} \
    -Dquarkus.native.java-home=${GRAALVM_HOME}

# ========================================
# Stage 2: Create runtime image
# ========================================
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3

WORKDIR /work/

# Copy the native executable
COPY --from=builder /build/quarkus-todo/target/quarkus-todo-1.0.0-SNAPSHOT-runner /work/application

# Set permissions for OpenShift
RUN chmod 775 /work/application && \
    chown -R 1001:0 /work && \
    chmod -R g=u /work

# Run as non-root user (required for OpenShift)
USER 1001

# Expose port
EXPOSE 8080

# Set environment variables
ENV QUARKUS_HTTP_PORT=8080

# Run the application
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
