#!/bin/bash

# Flux CD Bootstrap Script for scaleway-k8s-egres-proxy
# This script sets up Flux CD to manage the Kubernetes cluster
# using GitOps from the specified repository.

# Repository information
REPO_OWNER="Monitob"
REPO_NAME="scaleway-k8s-egres-proxy"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
TOKEN=${GITHUB_TOKEN_EGRESS}

# Cluster and namespace settings
CLUSTER_NAME="scaleway-k8s-egres-proxy"
TARGET_PATH="./manifests/overlays/production"
BRANCH="main"

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    echo "Flux CLI not found. Installing..."
    curl -s https://fluxcd.io/install.sh | sudo bash
fi

# Verify kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: kubectl is not configured to connect to a cluster"
    echo "Please configure kubectl before running this script"
    exit 1
fi

echo "Starting Flux CD bootstrap process..."
echo "Repository: ${REPO_URL}"
echo "Target path: ${TARGET_PATH}"
echo "Cluster: ${CLUSTER_NAME}"

# Bootstrap Flux CD
flux bootstrap github \
  --owner=${REPO_OWNER} \
  --repository=${REPO_NAME} \
  --branch=${BRANCH} \
  --path=${TARGET_PATH} \
  --token=${TOKEN} \
  --network-policy=false

if [ $? -eq 0 ]; then
    echo "✅ Flux CD successfully installed and configured"
    echo "👉 Flux will now synchronize with ${REPO_URL}"
    echo "👉 Monitoring path: ${TARGET_PATH}"

    # Verify installation
    echo "Checking Flux system status..."
    kubectl -n flux-system get pods
else
    echo "❌ Failed to install Flux CD"
    echo "Please check the error messages above and ensure:"
    echo "1. You have admin rights to the repository"
    echo "2. The repository exists"
    echo "3. Your kubectl is configured correctly"
    exit 1
fi

echo "Bootstrap process completed!"
