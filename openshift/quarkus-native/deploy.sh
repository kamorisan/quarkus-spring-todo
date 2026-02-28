#!/bin/bash
set -e

# ========================================
# Quarkus Native Serverless Deployment Script
# ========================================

# Configuration Variables
NAMESPACE="${OPENSHIFT_NAMESPACE:-demo-serverless}"
APP_NAME="quarkus-todo-native"
GIT_REPO="${GIT_REPO:-https://github.com/kamorisan/quarkus-spring-todo.git}"
GIT_BRANCH="${GIT_BRANCH:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  Deploying Quarkus Native to OpenShift"
echo "  Serverless (Knative Serving)"
echo "========================================="
echo ""
echo "Configuration:"
echo "  Namespace: $NAMESPACE"
echo "  App Name: $APP_NAME"
echo "  Git Repo: $GIT_REPO"
echo "  Git Branch: $GIT_BRANCH"
echo ""

# Check if logged in to OpenShift
echo "Checking OpenShift connection..."
if ! oc whoami &> /dev/null; then
    echo "Error: Not logged in to OpenShift"
    echo "Please login first: oc login <cluster-url>"
    exit 1
fi

echo "✓ Logged in as: $(oc whoami)"
echo "✓ Server: $(oc whoami --show-server)"
echo ""

# Create or switch to namespace
echo "Setting up namespace..."
if oc get namespace "$NAMESPACE" &> /dev/null; then
    echo "✓ Namespace '$NAMESPACE' already exists"
else
    echo "Creating namespace '$NAMESPACE'..."
    oc create namespace "$NAMESPACE"
fi

oc project "$NAMESPACE"
echo ""

# Create ImageStream
echo "Creating ImageStream..."
oc create imagestream "$APP_NAME" -n "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -
echo ""

# Create BuildConfig using Docker strategy
echo "Creating BuildConfig..."
cat <<EOF | oc apply -f -
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${APP_NAME}
spec:
  source:
    type: Git
    git:
      uri: ${GIT_REPO}
      ref: ${GIT_BRANCH}
    contextDir: openshift/quarkus-native
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
  output:
    to:
      kind: ImageStreamTag
      name: ${APP_NAME}:latest
  triggers: []
EOF

echo ""

# Start build
echo "Starting build..."
echo "This will take several minutes (Native Image compilation is slow)"
echo ""

oc start-build "$APP_NAME" -n "$NAMESPACE" --follow --wait

if [ $? -ne 0 ]; then
    echo ""
    echo "Error: Build failed"
    echo "Check build logs: oc logs -f bc/$APP_NAME -n $NAMESPACE"
    exit 1
fi

echo ""
echo "✓ Build completed successfully"
echo ""

# Get the image reference
IMAGE_REF=$(oc get imagestream "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.dockerImageRepository}'):latest

if [ -z "$IMAGE_REF" ]; then
    echo "Error: Could not get image reference"
    exit 1
fi

echo "Image: $IMAGE_REF"
echo ""

# Deploy Knative Service
echo "Deploying Knative Service..."
sed "s|IMAGE_PLACEHOLDER|$IMAGE_REF|g" "$SCRIPT_DIR/knative-service.yaml" | oc apply -f -

echo ""
echo "Waiting for service to be ready..."
echo "(This may take a minute)"
echo ""

# Wait for service to be ready (max 5 minutes)
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    READY=$(oc get ksvc "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")

    if [ "$READY" = "True" ]; then
        echo "✓ Service is ready!"
        break
    fi

    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "Waiting... ($ELAPSED/$TIMEOUT seconds)"
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ "$READY" != "True" ]; then
    echo "Warning: Service did not become ready within $TIMEOUT seconds"
    echo "Check status: oc get ksvc $APP_NAME -n $NAMESPACE"
    echo "Check events: oc get events -n $NAMESPACE --sort-by='.lastTimestamp'"
fi

echo ""
echo "========================================="
echo "  Deployment Complete!"
echo "========================================="
echo ""

# Get service URL
SERVICE_URL=$(oc get ksvc "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.url}' 2>/dev/null || echo "")

if [ -n "$SERVICE_URL" ]; then
    echo "Service URL: $SERVICE_URL"
    echo ""
    echo "Test the service:"
    echo "  curl $SERVICE_URL/q/health/ready"
    echo "  curl $SERVICE_URL/api/todos"
    echo ""
    echo "Create a todo:"
    echo "  curl -X POST $SERVICE_URL/api/todos \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"title\":\"Test from Serverless\",\"description\":\"Quarkus Native on OpenShift\"}'"
    echo ""
else
    echo "Could not retrieve service URL"
    echo "Check with: oc get ksvc $APP_NAME -n $NAMESPACE"
fi

echo "View service details:"
echo "  oc get ksvc $APP_NAME -n $NAMESPACE"
echo ""
echo "View logs:"
echo "  oc logs -f -l app=$APP_NAME -n $NAMESPACE"
echo ""
echo "Delete service:"
echo "  oc delete ksvc $APP_NAME -n $NAMESPACE"
echo "  oc delete bc $APP_NAME -n $NAMESPACE"
echo "  oc delete is $APP_NAME -n $NAMESPACE"
echo ""
