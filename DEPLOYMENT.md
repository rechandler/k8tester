# Deployment Guide for GCP (Kubernetes)

This guide will help you set up the GitHub Action to automatically deploy your NGINX reverse proxy to Google Kubernetes Engine (GKE).

## Prerequisites

1. **Google Cloud Project**: You'll need a GCP project with billing enabled (`pano-cam-dev`)
2. **GKE Cluster**: The cluster `rd-stage-cluster` should already exist in `us-central1`
3. **Google Cloud Services**: Enable the following APIs in your project:
   - Kubernetes Engine API
   - Artifact Registry API
   - Cloud Build API

## Setup Steps

### 1. Create a Service Account

```bash
# Set your project ID
export PROJECT_ID="pano-cam-dev"

# Create a service account
gcloud iam service-accounts create github-actions \
    --description="Service account for GitHub Actions" \
    --display-name="GitHub Actions"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.clusterViewer"

# Create and download a key file
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com
```

### 2. Create Artifact Registry Repository

```bash
# Create a repository for Docker images
gcloud artifacts repositories create preview-proxy \
    --repository-format=docker \
    --location=us-central1 \
    --description="Repository for preview proxy images"
```

### 3. Reserve Static IP (Optional but Recommended)

```bash
# Reserve a global static IP for the ingress
gcloud compute addresses create preview-proxy-ip \
    --global \
    --description="Static IP for preview proxy ingress"

# Get the IP address
gcloud compute addresses describe preview-proxy-ip --global
```

### 4. Set Up GitHub Secrets

In your GitHub repository, go to Settings > Secrets and variables > Actions, and add these secrets:

- **`GCP_SA_KEY`**: The contents of the `github-actions-key.json` file (copy the entire JSON)

### 5. Kubernetes Resources

The deployment includes these Kubernetes resources:

- **Deployment**: Runs 2 replicas of the NGINX proxy with health checks
- **Service**: ClusterIP service to expose the pods internally
- **Ingress**: Google Cloud Load Balancer with SSL termination
- **ManagedCertificate**: Automatic SSL certificate provisioning

## How It Works

The GitHub Action will:

1. **Trigger**: Run on pushes to `main` branch and on pull requests
2. **Build**: Create a Docker image from your Dockerfile
3. **Push**: Upload the image to Google Artifact Registry with both commit SHA and `:latest` tags
4. **Deploy**: Deploy to the existing GKE cluster `rd-stage-cluster` with:
   - 2 replicas for high availability
   - Resource limits (512Mi memory, 500m CPU)
   - Health checks for reliability
   - Load balancer with SSL termination

## Architecture

```
Internet → Google Cloud Load Balancer → GKE Ingress → Service → Deployment (2 pods)
```

The Ingress handles:

- SSL termination with managed certificates
- Routing `*.preview.pano.ai` and `preview.pano.ai` to the service
- Static IP assignment

## DNS Configuration

After deployment, you'll need to:

1. **Get the Load Balancer IP**:

   ```bash
   kubectl get ingress preview-proxy-ingress
   ```

2. **Configure DNS**: Point your DNS records to the Load Balancer IP:
   - `A` record for `preview.pano.ai` → `<LOAD_BALANCER_IP>`
   - `A` record for `*.preview.pano.ai` → `<LOAD_BALANCER_IP>`

## Monitoring and Logs

- **View logs**: `kubectl logs -l app=preview-proxy -f`
- **Check status**: `kubectl get pods,svc,ingress -l app=preview-proxy`
- **Monitor in Console**: Visit the GKE and Cloud Load Balancing sections in Google Cloud Console

## Scaling

To adjust the number of replicas:

```bash
kubectl scale deployment preview-proxy --replicas=3
```

Or update the `replicas` field in `k8s/deployment.yaml` and commit the change.

## Security Notes

- The service uses a ClusterIP (internal only) with external access via Ingress
- SSL certificates are automatically managed by Google
- Consider adding NetworkPolicies for additional pod-to-pod security
- Review IAM permissions regularly and follow the principle of least privilege

## Troubleshooting

- **Certificate not ready**: Managed certificates can take 5-15 minutes to provision
- **404 errors**: Check that the DNS is pointing to the correct Load Balancer IP
- **Pod issues**: Use `kubectl describe pod <pod-name>` for debugging
- **Ingress issues**: Use `kubectl describe ingress preview-proxy-ingress`
