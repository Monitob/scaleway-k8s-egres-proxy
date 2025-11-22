# Multi-Tenancy with Egress Isolation via Proxy (Squid)

This document describes the architecture and configuration for supporting a **multi-tenancy** scenario in a Kubernetes cluster (Kapsule) using GitOps with Flux CD. The solution shares the *control plane* while isolating the *data plane* per client, particularly for outbound (*egress*) traffic. The implementation follows Kustomize overlay patterns for different environments and includes a demo application to demonstrate the functionality.

## 🎯 Objective

- Allow multiple clients to share the same Kubernetes cluster.
- Isolate compute and outbound network traffic (egress) per client.
- Ensure all outbound traffic from a client's pods goes through a dedicated fixed IP address.

---

## 🧱 Architecture

The solution implements a multi-environment deployment using Kustomize overlays. The architecture follows GitOps principles with Flux CD for automated synchronization.

### Directory Structure
```text
manifests/
├── base/
│   ├── client-egress-proxy-demo/
│   │   ├── namespace.yaml
│   │   └── deployment.yaml
│   └── kustomization.yaml
└── overlays/
    ├── development/
    │   ├── deployment-patch.yaml
    │   └── kustomization.yaml
    └── production/
        ├── deployment-patch.yaml
        └── kustomization.yaml
```

### Network Architecture
```text
+------------------+
|   Kapsule Cluster |
| (Private Network) |
| 172.16.28.0/22    |
+--------+---------+
         |
         | Cluster nodes
   +-----+-----+
   | Node Pool |
   | Client A  |
   +-----+-----+
         |
         | Taints & Tolerations
         | nodeSelector: node-pool=client-a-pool
         |
         v
+---------------------+
| Proxy VM (Squid)    |
| Private IP: 172.16.28.8 |
| Public IP: <Flexible IP> |
+---------------------+
         |
         v
Internet (Egress with fixed IP)
```

---

## 🔧 Key Components

### 1. Dedicated Node Pool (Compute Isolation)

- **Taint applied to Node Pool**:
  ```bash
  key=value:NoSchedule
  node-role.kubernetes.io/client-a=dedicated:NoSchedule
  ```
- Client pods use **Tolerations** to schedule only on these nodes.

### 2. Egress Proxy (Network Isolation)

- A VM instance (e.g., Stardust) running **Squid**.
- Private IP: `172.16.28.8` (accessible from the cluster).
- Public IP: Scaleway Flexible IP (ensures fixed IP for egress).
- All client pods use this IP as proxy.

### 3. Network Configuration

- The cluster and VM are in the same **Private Network (172.16.28.0/22)**.
- No complete network isolation to allow internal connectivity.

---

## 📄 Kubernetes Manifests

The following resources have been deployed:

### Namespace: `client-a-demo`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: client-a-demo
  labels:
    tenant: client-a
    network/isolation: egress-proxy
  annotations:
    description: "Namespace for client A egress traffic isolation via dedicated proxy"
```

### Deployment: `curl-demo`

The client egress proxy demo is configured using Kustomize overlays with environment-specific settings.

#### Base Configuration
The base manifest defines the common structure:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl-demo
  namespace: client-a-demo
spec:
  template:
    spec:
      containers:
        - name: curl
          image: curlimages/curl:latest
          command: [ "sh", "-c" ]
          args:
            - |
              echo "=== Iniciando prueba de salida (egress) ==="
              echo "Proxy configurado: $HTTP_PROXY"
              while true; do
                echo "=== $(date) ==="
                curl -s -o /dev/null -w "Código: %{http_code}, Duración: %{time_total}s\n" https://ifconfig.me/ip
                sleep 15
              done
```

#### Environment-Specific Configuration
The environment-specific settings are applied through overlays:

**Development Environment:**
- Replicas: 1
- Resource requests: 64Mi memory, 50m CPU
- Resource limits: 128Mi memory, 100m CPU
- Environment variables:
  ```yaml
  env:
    - name: HTTP_PROXY
      value: http://$(PROXY_ADDRESS):$(PROXY_PORT)
    - name: HTTPS_PROXY
      value: http://$(PROXY_ADDRESS):$(PROXY_PORT)
  ```
- Configuration:
  ```yaml
  configMapGenerator:
    - name: client-egress-config
      behavior: replace
      literals:
        - PROXY_ADDRESS=172.16.28.8
        - PROXY_PORT=3128
        - ENVIRONMENT=development
  ```

**Production Environment:**
- Replicas: 2
- Resource requests: 64Mi memory, 50m CPU
- Resource limits: 128Mi memory, 100m CPU
- Environment variables:
  ```yaml
  env:
    - name: HTTP_PROXY
      value: http://$(PROXY_ADDRESS):$(PROXY_PORT)
    - name: HTTPS_PROXY
      value: http://$(PROXY_ADDRESS):$(PROXY_PORT)
  ```
- Configuration:
  ```yaml
  configMapGenerator:
    - name: client-egress-config
      behavior: replace
      literals:
        - PROXY_ADDRESS=172.16.28.8
        - PROXY_PORT=3128
        - ENVIRONMENT=production
  ```

---

## ✅ Validation

To verify everything is working:

```bash
# View pod logs (should show consistent IPs)
kubectl logs -f -n client-a-demo deploy/curl-demo

# Execute curl manually
kubectl exec -n client-a-demo deploy/curl-demo -- curl -s https://ifconfig.me/ip
```

> 🔎 **Expected result**: The displayed IP should be the **public Flexible IP** of the Squid instance, not the cluster node's IP.

---

## 🔄 GitOps with Flux CD and Kustomize Overlays

The implementation follows GitOps principles using Flux CD and Kustomize overlays for environment-specific configurations.

### Directory Structure
The manifests are organized using the Kustomize overlay pattern:
- `manifests/base/`: Contains common, environment-agnostic configurations
- `manifests/overlays/development/`: Development-specific settings and patches
- `manifests/overlays/production/`: Production-specific settings and patches

### Flux CD Integration
Flux CD is configured to synchronize from the Git repository, applying the appropriate overlay based on the target environment.

**Development Setup:**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: client-egress-dev
  namespace: flux-system
spec:
  interval: 5m
  path: ./manifests/overlays/development
  prune: true
  sourceRef:
    kind: GitRepository
    name: scaleway-k8s-egres-proxy
```

**Production Setup:**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: client-egress-prod
  namespace: flux-system
spec:
  interval: 1m
  path: ./manifests/overlays/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: scaleway-k8s-egres-proxy
  # Additional production safeguards
  timeout: 5m
  retryInterval: 1m
```

### Deployment Workflow
1. Developers commit changes to feature branches
2. Changes are reviewed and merged to main branch
3. Flux CD automatically detects changes and applies the appropriate overlay
4. For production deployments, additional approval steps can be implemented

To deploy changes:
```bash
git add manifests/
git commit -m "Update client egress proxy configuration"
git push origin main
```

Flux will automatically apply the changes to the appropriate environment based on the overlay structure.

---

## 🖥️ Demo Application

A demo web application has been implemented to showcase the egress proxy functionality. The application provides an interactive interface to test connectivity through the proxy.

### Features
- Displays system information about the pod and node
- Tests external IP address visibility (should show the proxy's IP)
- Connects to external APIs (ipinfo.io, httpbin.org) through the proxy
- Interactive buttons to test different connectivity scenarios
- Real-time updates and error handling

### Architecture
- **Frontend**: Simple web interface served by NGINX
- **Content**: HTML/CSS/JavaScript for the user interface
- **Proxy Integration**: Configured with HTTP_PROXY and HTTPS_PROXY environment variables
- **Deployment**: Single replica with appropriate resource requests
- **Security**: Implements RBAC and NetworkPolicy for least privilege access

### Security Implementation
The demo application includes several security features to protect the cluster:

**RBAC Configuration**:
- Dedicated ServiceAccount with minimal required permissions
- Role with get/list/watch access to pods, services, and endpoints
- RoleBinding connecting the ServiceAccount to the Role

**Network Policy**:
- Allows ingress only from pods within the same application
- Restricts egress traffic to:
  - The proxy server (172.16.28.8:3128)
  - The scaleway-proxy service on port 51122
  - DNS traffic (port 53) to external networks
  - HTTPS/HTTP traffic (ports 80/443) to external networks
- Blocks all other traffic by default

### Getting Started with the Demo Application

To deploy and use the demo application:

1. **Deploy the application**:
   ```bash
   # The application is included in the base kustomization
   # It will be deployed automatically when you apply the manifests
   kubectl apply -k manifests/base
   ```

2. **Verify the deployment**:
   ```bash
   # Check if the namespace exists
   kubectl get namespace client-a-demo
   
   # Check the pods in the namespace
   kubectl get pods -n client-a-demo
   
   # Check the service
   kubectl get service -n client-a-demo
   ```

3. **Access the application**:
   ```bash
   # Use port forwarding to access the web interface
   kubectl port-forward svc/demo-web-app -n client-a-demo 8080:80
   ```

4. **Open your browser** and navigate to `http://localhost:8080`

5. **Test the functionality**:
   - Click "Test External IP" to verify traffic goes through the proxy
   - Click "Test ipinfo.io" and "Test httpbin.org" to test external API access
   - Check the system information section for pod details

### Troubleshooting

If you encounter issues:

1. **Check pod status**:
   ```bash
   kubectl get pods -n client-a-demo
   kubectl describe pod -n client-a-demo -l app=demo-web-app
   ```

2. **Check pod logs**:
   ```bash
   kubectl logs -n client-a-demo -l app=demo-web-app
   ```

3. **Verify network connectivity**:
   ```bash
   # Exec into the pod
   kubectl exec -it -n client-a-demo -l app=demo-web-app -- sh
   
   # Test connectivity to the proxy
   curl -v http://172.16.28.8:3128
   ```

4. **Check network policies**:
   ```bash
   kubectl get networkpolicies -n client-a-demo
   kubectl describe networkpolicy -n client-a-demo demo-web-app
   ```

### Testing the Demo
1. Access the application through port forwarding:
   ```bash
   kubectl port-forward svc/demo-web-app -n client-a-demo 8080:80
   ```
2. Open http://localhost:8080 in your browser
3. Click the "Test External IP" button
4. Verify that the IP shown matches your proxy's public IP

The demo application confirms that:
- The pod is properly configured with proxy environment variables
- External connectivity works through the proxy
- The egress isolation is functioning correctly
- Network policies are not blocking legitimate traffic

### Security Best Practices
- The demo application implements security best practices that should be followed in production:
  - Principle of least privilege for service accounts
  - Network segmentation using NetworkPolicy
  - Separation of concerns between application components
- For production environments, consider enhancing security with:
  - Authentication and authorization for web interfaces
  - Rate limiting for external API calls
  - Regular security audits and penetration testing
  - Monitoring and alerting for security events
  - Regular patching of base images and dependencies

---

## 📌 Operational Notes

## 🖥️ Demo Application

A demo web application has been implemented to showcase the egress proxy functionality. The application provides an interactive interface to test connectivity through the proxy.

### Features
- Displays system information about the pod and node
- Tests external IP address visibility (should show the proxy's IP)
- Connects to external APIs (ipinfo.io, httpbin.org) through the proxy
- Interactive buttons to test different connectivity scenarios
- Real-time updates and error handling

### Architecture
- **Frontend**: Simple web interface served by NGINX
- **Content**: HTML/CSS/JavaScript for the user interface
- **Proxy Integration**: Configured with HTTP_PROXY and HTTPS_PROXY environment variables
- **Deployment**: Single replica with appropriate resource requests

### Testing the Demo
1. Access the application through port forwarding:
   ```bash
   kubectl port-forward svc/demo-web-app -n client-a-demo 8080:80
   ```
2. Open http://localhost:8080 in your browser
3. Click the "Test External IP" button
4. Verify that the IP shown matches your proxy's public IP

The demo application confirms that:
- The pod is properly configured with proxy environment variables
- External connectivity works through the proxy
- The egress isolation is functioning correctly

### Security Considerations
- The demo application is for demonstration purposes only
- In production, consider implementing additional security measures:
  - Network policies to restrict traffic
  - Authentication for the web interface
  - Rate limiting for external API calls
  - Regular security audits

## 📌 Operational Notes

- Ensure the **client's Node Pool is properly labeled and tainted**:
  ```bash
  node-role.kubernetes.io/client-a=dedicated:NoSchedule
  ```
- Verify the **VM firewall allows traffic** from `172.16.28.0/22` on port `3128`.
- Using `HTTP_PROXY` and `HTTPS_PROXY` is transparent for most applications.
- The overlay pattern allows for environment-specific configurations while maintaining consistency across environments.
- The `$(PROXY_ADDRESS)` and `$(PROXY_PORT)` variables are resolved from the ConfigMap at runtime.
- Consider implementing additional security measures for production, such as:
  - Network policies to restrict traffic
  - Regular security audits of the proxy configuration
  - Monitoring and alerting for proxy health and performance

---

## 🚀 Next Steps

- Automate Node Pool creation per client (with Terraform).
- Implement proxy monitoring (logs, availability).
- Implement automated testing of the egress proxy configuration.
- Add network policies to further restrict traffic between tenants.
- Consider implementing client certificate authentication for the proxy.
- Set up centralized logging and monitoring for all client egress traffic.
- Implement automated security scanning for the proxy configuration.
- Add support for multiple proxy instances for high availability.
- Document disaster recovery procedures for the proxy infrastructure.