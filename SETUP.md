# Setup Guide

This guide will help you set up the Scaleway Kubernetes Egress Proxy system securely.

## Prerequisites

Before you begin, ensure you have:

- [Terraform](https://www.terraform.io/downloads.html) installed (version 1.0 or higher)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed and configured
- [Flux CLI](https://fluxcd.io/docs/installation/#install-the-flux-cli) installed
- Scaleway account with API credentials configured
- Access to a Kubernetes cluster (Kapsule)

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Monitob/scaleway-k8s-egres-proxy.git
cd scaleway-k8s-egres-proxy
```

### 2. Configure Environment

Create your environment configuration files from the templates:

```bash
# Create production config
cp manifests/config/templates/prod.env.tpl manifests/config/prod.env

# Create development config  
cp manifests/config/templates/dev.env.tpl manifests/config/dev.env
```

Edit the files with your specific values:

```bash
nano manifests/config/prod.env
nano manifests/config/dev.env
```

## Secrets Management

**Important**: Never commit sensitive information to Git.

### 1. Set Up Kubernetes Secrets

Use the interactive script to set up your secrets:

```bash
# For production
./scripts/setup-secrets.sh production

# For development
./scripts/setup-secrets.sh development
```

The script will prompt you for each secret value and create/update the Kubernetes secret securely.

### 2. Alternative: Manual Secret Creation

If you prefer to create secrets manually:

```bash
kubectl create secret generic scaleway-proxy-secrets \
  --namespace=client-a-demo \
  --from-literal=JWT_SECRET=your-jwt-secret \
  --from-literal=DATABASE_URL=your-database-url \
  --from-literal=QDRANT_API_KEY=your-qdrant-key
```

## Environment Configuration

### Development Environment

For local development, you can use a `.env` file:

```bash
cp .env.example .env
nano .env
source .env
```

## Deployment

### 1. Bootstrap Flux CD

If this is a new cluster, bootstrap Flux:

```bash
flux bootstrap github \
  --owner=Monitob \
  --repository=scaleway-k8s-egres-proxy \
  --branch=main \
  --path=manifests/overlays/production \
  --personal
```

### 2. Apply Configuration

For existing Flux setup, ensure your changes are pushed:

```bash
git add .
git commit -m "Update configuration"
git push origin main
```

Flux will automatically sync the changes.

## Security Best Practices

1. **Never commit secrets** to version control
2. **Rotate secrets** regularly
3. Use **least privilege** for service accounts
4. **Audit access** to sensitive resources
5. Store sensitive data in **Kubernetes secrets**, not in manifests
6. Use **network policies** to restrict traffic

## Troubleshooting

### Common Issues

#### 1. Missing Configuration Files

If you get errors about missing config files:

```bash
# Ensure you've created the config files from templates
ls manifests/config/*.env
```

#### 2. Secrets Not Found

If your application can't find secrets:

```bash
# Check if secrets exist in the namespace
kubectl get secrets -n client-a-demo

# Recreate if necessary
./scripts/setup-secrets.sh
```

#### 3. Flux Sync Issues

If Flux is not syncing:

```bash
# Check Flux status
flux get kustomizations
flux get sources git

# Reconcile manually
flux reconcile source git flux-system
flux reconcile kustomization flux-system
```

## Next Steps

1. Verify your application is running:
```bash
kubectl get pods -n client-a-demo
```

2. Access the demo application:
```bash
kubectl port-forward svc/egress-multitenant-demo -n client-a-demo 8080:80
```

3. Open http://localhost:8080 in your browser.

For more information, see the [README.md](README.md) file.