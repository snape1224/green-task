# OpenShift Deployment Guide

This guide explains how to deploy GreenTasker to OpenShift Sandbox.

## Prerequisites

- Access to OpenShift Sandbox (or any OpenShift cluster)
- `oc` CLI tool installed and configured
- Docker/Podman for building images

## Deployment Steps

### 1. Build and Push Backend Image

```bash
# Navigate to backend directory
cd backend

# Build the Docker image
docker build -t <your-registry>/green-tasker-backend:latest .

# Or if using Podman:
podman build -t <your-registry>/green-tasker-backend:latest .

# Push to your registry
docker push <your-registry>/green-tasker-backend:latest
```

### 2. Create Frontend ConfigMap

```bash
# Create ConfigMap with frontend files
oc create configmap frontend-html \
  --from-file=../frontend/index.html \
  --from-file=../frontend/app.js \
  --from-file=../frontend/style.css
```

### 3. Deploy Backend

```bash
# Update the image in backend-deployment.yaml
# Replace <your-registry> with your actual registry URL

# Apply backend deployment
oc apply -f openshift/backend-deployment.yaml

# Wait for backend to be ready
oc rollout status deployment/green-tasker-backend
```

### 4. Get Backend Route URL

```bash
# Get the backend route hostname
BACKEND_ROUTE=$(oc get route green-tasker-backend -o jsonpath='{.spec.host}')

# Determine scheme (usually https for OpenShift)
BACKEND_URL="https://${BACKEND_ROUTE}"

echo "Backend URL: ${BACKEND_URL}"
```

### 5. Configure Frontend with Backend URL

```bash
# Update frontend ConfigMap with backend URL
oc set data configmap/frontend-config backend-url="${BACKEND_URL}"

# Or create it if it doesn't exist
oc create configmap frontend-config \
  --from-literal=backend-url="${BACKEND_URL}"
```

### 6. Deploy Frontend

```bash
# Apply frontend deployment
oc apply -f openshift/frontend-deployment.yaml

# Wait for frontend to be ready
oc rollout status deployment/green-tasker-frontend
```

### 7. Access the Application

```bash
# Get frontend route
oc get route green-tasker-frontend

# Open in browser or use:
FRONTEND_URL=$(oc get route green-tasker-frontend -o jsonpath='{.spec.host}')
echo "Frontend URL: https://${FRONTEND_URL}"
```

## Quick Deployment Script

You can also use the provided setup script:

```bash
# Make script executable
chmod +x openshift/setup-frontend-config.sh

# Run setup (after backend is deployed)
./openshift/setup-frontend-config.sh
```

## Troubleshooting

### Backend not starting
- Check logs: `oc logs deployment/green-tasker-backend`
- Verify image exists: `oc describe deployment/green-tasker-backend`
- Check port configuration matches (5000)

### Frontend can't connect to backend
- Verify backend route exists: `oc get route green-tasker-backend`
- Check frontend ConfigMap: `oc get configmap frontend-config -o yaml`
- Verify BACKEND_URL is set correctly
- Check browser console for CORS errors (should be fixed with flask-cors)

### CORS Issues
- Ensure `flask-cors` is installed in requirements.txt
- Verify CORS is enabled in app.py: `CORS(app)`

## Configuration

### Environment Variables

**Backend:**
- `PORT`: Port to run on (default: 5000)

**Frontend:**
- `BACKEND_URL`: Backend API URL (from ConfigMap)

## Notes

- The backend stores tasks in memory (will be lost on pod restart)
- For production, consider adding a database
- Update image registry URLs in deployment files before deploying
- OpenShift routes typically use HTTPS automatically

