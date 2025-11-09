#!/bin/bash
# Complete OpenShift deployment script for GreenTasker
# Usage: ./deploy.sh [namespace] [registry-url]

set -e

NAMESPACE=${1:-$(oc project -q)}
REGISTRY=${2:-"image-registry.openshift-image-registry.svc:5000/${NAMESPACE}"}

echo "========================================="
echo "GreenTasker OpenShift Deployment"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "Registry: $REGISTRY"
echo ""

# Check if oc is available
if ! command -v oc &> /dev/null; then
    echo "Error: 'oc' CLI tool is not installed or not in PATH"
    echo "Please install OpenShift CLI: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html"
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    echo "Error: Not logged in to OpenShift. Please run 'oc login' first"
    exit 1
fi

echo "Step 1: Building backend Docker image..."
cd backend
docker build -t ${REGISTRY}/green-tasker-backend:latest . || podman build -t ${REGISTRY}/green-tasker-backend:latest .
echo "✓ Backend image built"

echo ""
echo "Step 2: Pushing backend image to registry..."
docker push ${REGISTRY}/green-tasker-backend:latest || podman push ${REGISTRY}/green-tasker-backend:latest
echo "✓ Backend image pushed"

cd ..

echo ""
echo "Step 3: Creating frontend ConfigMap..."
oc create configmap frontend-html \
  --from-file=index.html=frontend/index.html \
  --from-file=app.js=frontend/app.js \
  --from-file=style.css=frontend/style.css \
  --dry-run=client -o yaml | oc apply -f -
echo "✓ Frontend ConfigMap created"

echo ""
echo "Step 4: Updating backend deployment with image..."
sed "s|<your-registry>|${REGISTRY}|g" openshift/backend-deployment.yaml | oc apply -f -
echo "✓ Backend deployment updated"

echo ""
echo "Step 5: Waiting for backend to be ready..."
oc rollout status deployment/green-tasker-backend -n $NAMESPACE --timeout=5m
echo "✓ Backend is ready"

echo ""
echo "Step 6: Getting backend route URL..."
BACKEND_ROUTE=$(oc get route green-tasker-backend -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -z "$BACKEND_ROUTE" ]; then
    echo "Warning: Backend route not found. Creating route..."
    oc expose service green-tasker-backend -n $NAMESPACE
    BACKEND_ROUTE=$(oc get route green-tasker-backend -n $NAMESPACE -o jsonpath='{.spec.host}')
fi
BACKEND_URL="https://${BACKEND_ROUTE}"
echo "✓ Backend URL: $BACKEND_URL"

echo ""
echo "Step 7: Configuring frontend with backend URL..."
oc create configmap frontend-config \
  --from-literal=backend-url="$BACKEND_URL" \
  --dry-run=client -o yaml | oc apply -f -
echo "✓ Frontend configured"

echo ""
echo "Step 8: Deploying frontend..."
oc apply -f openshift/frontend-deployment.yaml
echo "✓ Frontend deployment applied"

echo ""
echo "Step 9: Waiting for frontend to be ready..."
oc rollout status deployment/green-tasker-frontend -n $NAMESPACE --timeout=5m
echo "✓ Frontend is ready"

echo ""
echo "Step 10: Getting frontend route..."
FRONTEND_ROUTE=$(oc get route green-tasker-frontend -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -z "$FRONTEND_ROUTE" ]; then
    echo "Warning: Frontend route not found. Creating route..."
    oc expose service green-tasker-frontend -n $NAMESPACE
    FRONTEND_ROUTE=$(oc get route green-tasker-frontend -n $NAMESPACE -o jsonpath='{.spec.host}')
fi
FRONTEND_URL="https://${FRONTEND_ROUTE}"
echo "✓ Frontend URL: $FRONTEND_URL"

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo "Frontend URL: $FRONTEND_URL"
echo "Backend URL: $BACKEND_URL"
echo ""
echo "Your application is now publicly accessible!"
echo ""

