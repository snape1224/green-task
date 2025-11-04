#!/bin/bash
# Script to set up frontend ConfigMap with backend route URL
# Run this after deploying the backend to get the route URL

NAMESPACE=${1:-$(oc project -q)}
BACKEND_ROUTE=$(oc get route green-tasker-backend -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)

if [ -z "$BACKEND_ROUTE" ]; then
    echo "Error: Backend route not found. Make sure the backend is deployed first."
    exit 1
fi

# Determine if route uses https or http
SCHEME="https"
if [[ "$BACKEND_ROUTE" == *"apps.sandbox"* ]] || [[ "$BACKEND_ROUTE" == *"apps.cluster"* ]]; then
    SCHEME="https"
fi

BACKEND_URL="${SCHEME}://${BACKEND_ROUTE}"

echo "Setting backend URL to: $BACKEND_URL"

# Update the ConfigMap
oc create configmap frontend-config \
    --from-literal=backend-url="$BACKEND_URL" \
    --dry-run=client -o yaml | oc apply -f -

echo "Frontend ConfigMap updated successfully!"
echo "Backend URL: $BACKEND_URL"

