#!/bin/bash
set -e

# ========================================
# Todo UI Deployment Script
# Standard Deployment Only (No Serverless)
# ========================================

# Check arguments
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments"
    echo ""
    echo "Usage: $0 <BACKEND_APP_NAME> <BACKEND_TYPE> [BACKEND_NAMESPACE]"
    echo ""
    echo "Arguments:"
    echo "  BACKEND_APP_NAME  - Name of the backend Todo application (required)"
    echo "                      Example: quarkus-todo-jvm, spring-todo-jvm, quarkus-todo-native"
    echo "  BACKEND_TYPE      - Type of backend (quarkus or spring) (required)"
    echo "                      Values: quarkus | spring"
    echo "  BACKEND_NAMESPACE - Namespace where backend app is deployed (optional)"
    echo "                      Default: demo-apps"
    echo ""
    echo "Examples:"
    echo "  # Deploy with Quarkus backend in same namespace"
    echo "  $0 quarkus-todo-jvm quarkus"
    echo ""
    echo "  # Deploy with Spring Boot backend in same namespace"
    echo "  $0 spring-todo-jvm spring"
    echo ""
    echo "  # Deploy with backend in different namespace"
    echo "  $0 quarkus-todo-native quarkus demo-serverless"
    echo ""
    exit 1
fi

# Parse arguments
BACKEND_APP_NAME="$1"
BACKEND_TYPE="$2"
BACKEND_NAMESPACE="${3:-demo-apps}"

# Generate internal Service URL
# OpenShift internal Service URL format: http://<service-name>.<namespace>.svc.cluster.local:8080
# Or simply: http://<service-name>:8080 (if in same namespace)
if [ "$BACKEND_NAMESPACE" = "${OPENSHIFT_NAMESPACE:-demo-apps}" ]; then
    # Same namespace - use short name
    BACKEND_URL="http://${BACKEND_APP_NAME}:8080"
else
    # Different namespace - use FQDN
    BACKEND_URL="http://${BACKEND_APP_NAME}.${BACKEND_NAMESPACE}.svc.cluster.local:8080"
fi

# Validate BACKEND_TYPE
if [[ "$BACKEND_TYPE" != "quarkus" && "$BACKEND_TYPE" != "spring" ]]; then
    echo "Error: Invalid BACKEND_TYPE"
    echo "BACKEND_TYPE must be either 'quarkus' or 'spring'"
    echo "You provided: $BACKEND_TYPE"
    exit 1
fi

# Configuration Variables
NAMESPACE="${OPENSHIFT_NAMESPACE:-demo-apps}"
APP_NAME="todo-ui"
GIT_REPO="${GIT_REPO:-https://github.com/kamorisan/quarkus-spring-todo.git}"
GIT_BRANCH="${GIT_BRANCH:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  Deploying Todo UI to OpenShift"
echo "  Mode: Standard (Deployment)"
echo "========================================="
echo ""
echo "Configuration:"
echo "  Namespace: $NAMESPACE"
echo "  App Name: $APP_NAME"
echo "  Backend App: $BACKEND_APP_NAME"
echo "  Backend Namespace: $BACKEND_NAMESPACE"
echo "  Backend URL (Internal): $BACKEND_URL"
echo "  Backend Type: $BACKEND_TYPE"
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
    contextDir: openshift/todo-ui
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
echo "This will take a few minutes..."
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

# Deploy Deployment
echo "Deploying Deployment..."
sed -e "s|IMAGE_PLACEHOLDER|$IMAGE_REF|g" \
    -e "s|BACKEND_URL_PLACEHOLDER|$BACKEND_URL|g" \
    -e "s|BACKEND_TYPE_PLACEHOLDER|$BACKEND_TYPE|g" \
    "$SCRIPT_DIR/deployment.yaml" | oc apply -f -

echo "Deploying Service..."
oc apply -f "$SCRIPT_DIR/service.yaml"

echo "Deploying Route..."
oc apply -f "$SCRIPT_DIR/route.yaml"

echo ""
echo "Waiting for deployment to be ready..."
echo ""

# Wait for deployment to be ready (max 5 minutes)
oc rollout status deployment/$APP_NAME -n "$NAMESPACE" --timeout=300s

# Label deployment
oc label deployment/$APP_NAME -n "$NAMESPACE" app.openshift.io/runtime=quarkus --overwrite

echo ""
echo "========================================="
echo "  Deployment Complete!"
echo "========================================="
echo ""

# Get route URL
ROUTE_URL=$(oc get route "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

if [ -n "$ROUTE_URL" ]; then
    echo "Route URL: https://$ROUTE_URL"
    echo ""
    echo "Configuration:"
    echo "  Backend URL: $BACKEND_URL"
    echo "  Backend Type: $BACKEND_TYPE"
    echo ""
    echo "Test the UI:"
    echo "  Open in browser: https://$ROUTE_URL"
    echo ""
    echo "Test the API:"
    echo "  curl https://$ROUTE_URL/q/health/ready"
    echo "  curl https://$ROUTE_URL/api/backend/info"
    echo "  curl https://$ROUTE_URL/api/backend/health"
    echo "  curl https://$ROUTE_URL/api/todos"
    echo ""
else
    echo "Could not retrieve route URL"
    echo "Check with: oc get route $APP_NAME -n $NAMESPACE"
fi

echo "View deployment details:"
echo "  oc get deployment $APP_NAME -n $NAMESPACE"
echo ""
echo "View pods:"
echo "  oc get pods -n $NAMESPACE -l app=$APP_NAME"
echo ""
echo "View logs:"
echo "  oc logs -f -l app=$APP_NAME -n $NAMESPACE"
echo ""
echo "Scale deployment:"
echo "  oc scale deployment/$APP_NAME -n $NAMESPACE --replicas=3"
echo ""
echo "Delete resources:"
echo "  oc delete deployment $APP_NAME -n $NAMESPACE"
echo "  oc delete service $APP_NAME -n $NAMESPACE"
echo "  oc delete route $APP_NAME -n $NAMESPACE"
echo "  oc delete bc $APP_NAME -n $NAMESPACE"
echo "  oc delete is $APP_NAME -n $NAMESPACE"
echo ""
