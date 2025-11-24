# Egress Multitenant Demo Application

This application demonstrates multi-tenancy with egress proxy isolation in Kubernetes. It's designed to show how workloads can be isolated while sharing a cluster control plane.

## Application Overview

A Go-based web application that:
- Shows system information (pod, node, namespace)
- Tests external IP connectivity through a proxy
- Connects to external APIs (ipinfo.io, httpbin.org) via the proxy
- Provides an interactive web interface

## Architecture

```
Frontend (HTML/CSS/JS) ↔ Backend (Go Server) ↔ External Services
                               ↓
                        Egress Proxy (Squid)
                               ↓
                          Public Internet
```

## Development Setup

1. Install Go 1.23+
2. Install Docker
3. Set up Scaleway registry access

## Building Locally

```bash
# Build the Go binary
go build -o main src/main.go

# Run locally (without Docker)
POD_NAME="local-dev" \
POD_NAMESPACE="local" \
NODE_NAME="local-node" \
HTTP_PROXY="http://172.16.28.8:3128" \
HTTPS_PROXY="http://172.16.28.8:3128" \
./main
```

## Docker Build

```bash
# Build the container
docker build -t egress-multitenant-demo .

# Run container
docker run -p 8080:8080 \
  -e HTTP_PROXY=http://172.16.28.8:3128 \
  -e HTTPS_PROXY=http://172.16.28.8:3128 \
  egress-multitenant-demo
```

## Deployment Process

The application uses Makefile targets for streamlined operations:

```bash
# Build the Docker image
make build

# Build and push to Scaleway registry
make push

# Build, push, and deploy to Kubernetes
make deploy
```

## Environment Variables

| Variable | Description | Default |
|---------|-------------|---------|
| `HTTP_PROXY` | HTTP proxy URL | http://172.16.28.8:3128 |
| `HTTPS_PROXY` | HTTPS proxy URL | http://172.16.28.8:3128 |
| `PROXY_URL` | Proxy URL for display | http://172.16.28.8:3128 |
| `PROXY_CONFIG` | Proxy configuration method | HTTP_PROXY and HTTPS_PROXY environment variables |
| `POD_NAME` | Pod name (automatically set in K8s) | - |
| `NODE_NAME` | Node name (automatically set in K8s) | - |
| `POD_NAMESPACE` | Namespace (automatically set in K8s) | - |
| `HOST_INTERFACE` | Network interface to use | eth0 |

## Security Features

- Minimal Docker image (alpine base)
- Dedicated ServiceAccount with least privilege
- NetworkPolicy restricting traffic
- Proper error handling and timeouts

## Troubleshooting

### Common Issues

1. **Connection timeouts to external services**:
   - Verify proxy server (172.16.28.8:3128) is reachable
   - Check firewall rules allow traffic on port 3128
   - Verify proxy service is running

2. **Application fails to start**:
   - Check required environment variables are set
   - Verify container has proper network access
   - Check Kubernetes events: `kubectl describe pod <pod-name>`

3. **Port forwarding not working**:
   - Verify the service exists: `kubectl get svc -n client-a-demo`
   - Check the pod is running: `kubectl get pods -n client-a-demo`
   - Verify the port numbers match between service and deployment
