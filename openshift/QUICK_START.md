# Quick Start: Deploy to OpenShift Sandbox

## Prerequisites

1. **OpenShift Sandbox Account**: Sign up at https://developers.redhat.com/developer-sandbox
2. **OpenShift CLI**: Install `oc` CLI tool
3. **Docker or Podman**: For building images locally (or use OpenShift BuildConfig)

## Option 1: Using OpenShift Internal Registry (Recommended for Sandbox)

OpenShift Sandbox provides a built-in image registry. Here's the easiest way:

### Step 1: Login to OpenShift
```bash
oc login --token=<your-token> --server=<your-server-url>
```

### Step 2: Create a new project (if needed)
```bash
oc new-project green-tasker
```

### Step 3: Build image using OpenShift BuildConfig (No Docker needed!)

Create a BuildConfig that builds from your Dockerfile:

```bash
# Create BuildConfig for backend
oc new-build --name=green-tasker-backend \
  --binary \
  --strategy=docker \
  --to=green-tasker-backend:latest

# Start the build from local source
cd backend
oc start-build green-tasker-backend --from-dir=. --follow
cd ..
```

### Step 4: Deploy using the script
```bash
# Make script executable (Linux/Mac)
chmod +x openshift/deploy.sh

# Run deployment (uses internal registry automatically)
./openshift/deploy.sh
```

Or manually follow the steps in `DEPLOYMENT.md`

## Option 2: Using External Registry (Docker Hub, Quay.io, etc.)

### Step 1: Build and push to your registry
```bash
cd backend
docker build -t <your-username>/green-tasker-backend:latest .
docker push <your-username>/green-tasker-backend:latest
cd ..
```

### Step 2: Update deployment file
Edit `openshift/backend-deployment.yaml` and replace `<your-registry>` with your registry:
- Docker Hub: `docker.io/<your-username>/green-tasker-backend:latest`
- Quay.io: `quay.io/<your-username>/green-tasker-backend:latest`

### Step 3: Deploy
```bash
oc apply -f openshift/backend-deployment.yaml
# ... follow remaining steps from DEPLOYMENT.md
```

## Option 3: Using the Automated Script

If you have Docker/Podman installed:

```bash
# Make executable (Linux/Mac)
chmod +x openshift/deploy.sh

# Run (will use OpenShift internal registry by default)
./openshift/deploy.sh

# Or specify namespace and registry
./openshift/deploy.sh my-namespace docker.io/myusername
```

## Accessing Your Application

After deployment, get your public URL:

```bash
oc get route green-tasker-frontend
```

The route will be something like:
- `https://green-tasker-frontend-<namespace>.apps.sandbox-m2.ll9k.p1.openshiftapps.com`

## Important Notes

1. **OpenShift Sandbox**: Free tier with some limitations (CPU, memory, storage)
2. **HTTPS**: Routes automatically use HTTPS (certificates managed by OpenShift)
3. **Data Persistence**: Current setup uses in-memory storage (data lost on restart)
4. **Resource Limits**: Sandbox has resource quotas - monitor with `oc describe quota`

## Troubleshooting

### Check pod status
```bash
oc get pods
oc logs deployment/green-tasker-backend
oc logs deployment/green-tasker-frontend
```

### Check routes
```bash
oc get routes
```

### Restart deployments
```bash
oc rollout restart deployment/green-tasker-backend
oc rollout restart deployment/green-tasker-frontend
```

### Delete everything (cleanup)
```bash
oc delete -f openshift/backend-deployment.yaml
oc delete -f openshift/frontend-deployment.yaml
oc delete configmap frontend-html frontend-config
```

## Next Steps

- Add persistent storage for tasks (database)
- Set up monitoring and logging
- Configure resource limits
- Add health checks
- Set up CI/CD pipeline

