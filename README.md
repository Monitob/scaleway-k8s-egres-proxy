# Scaleway Kubernetes Egress Proxy Architecture

This repository implements a secure egress pattern for Kubernetes clusters on Scaleway, providing a controlled and auditable way for cluster outbound traffic to reach external services.

## 🔐 Security and Secrets Management

**Important**: This repository follows security best practices by NOT storing sensitive information in Git. Configuration and secrets must be managed separately.

### Sensitive Data Handling

The following sensitive information is **NOT** stored in this repository:
- API keys and secrets
- Database connection strings
- Environment-specific credentials
- Any other sensitive configuration values

### Secure Setup Process

To deploy this system securely:

1. **Create configuration files locally**:
```bash
# Create production config
cp manifests/config/templates/prod.env.tpl manifests/config/prod.env
# Edit with your values
nano manifests/config/prod.env

# Create development config  
cp manifests/config/templates/dev.env.tpl manifests/config/dev.env
# Edit with your values
nano manifests/config/dev.env
```

2. **Set up secrets securely**:
```bash
# Run the interactive secrets setup script
./scripts/setup-secrets.sh production
# or
./scripts/setup-secrets.sh development
```

3. **Environment Variables**:
All sensitive values are provided through environment variables or Kubernetes secrets, never committed to Git.

### Security Best Practices

- **Never commit secrets**: Ensure `*.env`, `*.secret`, and similar files are in `.gitignore`
- **Use Kubernetes secrets**: Store sensitive data in Kubernetes secrets, not in manifests
- **Regular rotation**: Rotate API keys and passwords periodically
- **Least privilege**: Grant only necessary permissions to service accounts
- **Audit access**: Monitor and log access to sensitive resources

### Development Workflow

For local development, you can use a `.env` file (already in `.gitignore`):

```bash
# Create .env file
cp .env.example .env
# Edit with your local values
nano .env

# Source the environment variables
source .env

# Now deploy your application
kubectl apply -k manifests/overlays/development
```

Remember to never commit your `.env` file to version control.

## Architecture Overview

This solution implements an Egress Proxy pattern that provides a robust and maintainable architecture for outbound traffic from private Kubernetes clusters.

### ASCII Architecture Diagram

```
+---------------------------------------------------+
|                    Scaleway VPC                 |
|                                                   |
|  +----------------+     +---------------------+  |
|  |                |     |                     |  |
|  |  Kubernetes    |     |    Proxy VM         |  |
|  |  Cluster       |     |    (Squid)          |  |
|  |                |     |                     |  |
|  |  +-----------+ |     |  +----------------+ |  |
|  |  | Worker    | |     |  | cloud-init     | |  |
|  |  | Nodes     | |     |  | - Install Squid| |  |
|  |  +-----------+ |     |  | - Configure    | |  |
|  |                |     |  |   firewall     | |  |
|  |                |     |  +----------------+ |  |
|  |                |     |                     |  |
|  |                |     |  +----------------+ |  |
|  |                |     |  | Flexible IP    |<-----> Public Internet
|  +----------------+     |  | (Public IP)    | |  |
|       |                 |  +----------------+ |  |
|       |                 |        |            |  |
|       +------------------> Proxy Port 3128    |  |
|                         |        |            |  |
|                         |        v            |  |
|                         |  +----------------+ |  |
|                         |  | Security Group | |  |
|                         |  | - Allow SSH    | |  |
|                         |  | - Allow 3128  | |  |
|                         |  +----------------+ |  |
|                                                   |
|  +----------------------------------------------+ |
|  |                   Public Gateway             | |
|  | - VPC-GW-S                                   | |
|  | - Masquerade/NAT                             | |
|  +----------------------------------------------+ |
|                           |                        |
+---------------------------------------------------+
                           |
                           v
                    Internet Traffic
```

### Key Components

1. **Kubernetes Cluster**:
   - Private cluster connected to VPC
   - Worker nodes without public IPs
   - All outbound traffic routed through proxy

2. **Proxy VM (Squid)**:
   - Small instance (e.g., PLAY2-S) in same VPC
   - Runs Squid proxy server
   - Configured via cloud-init
   - Has Flexible IP for internet access

3. **Public Gateway**:
   - VPC-GW-S instance
   - Provides NAT/masquerading
   - Routes traffic to internet
   - Attached to private network

4. **Security Configuration**:
   - Private network with internal CIDR
   - Security groups with restricted access
   - Firewall rules for SSH and proxy ports

### Traffic Flow

1. Application in Kubernetes pod makes outbound request
2. Traffic routed to Proxy VM on port 3128
3. Squid proxy forwards request through its public IP
4. Public Gateway performs NAT/masquerading
5. Traffic reaches internet destination
6. Response follows reverse path back to application

### Benefits

- **Security**: All outbound traffic is controlled and auditable
- **Predictable IP**: Single public IP address for whitelisting
- **Privacy**: Internal IPs hidden from external services
- **Maintainability**: Centralized proxy configuration
- **Scalability**: Can handle increased traffic by upgrading proxy VM

### Usage

To configure applications to use the proxy:

1. **Environment Variables**:
   ```yaml
   env:
   - name: HTTP_PROXY
     value: "http://172.16.28.8:3128"
   - name: HTTPS_PROXY
     value: "http://172.16.28.8:3128"
   - name: NO_PROXY
     value: "localhost,127.0.0.1,.svc.cluster.local,.cluster.local,.internal"
   ```

2. **Application Configuration**: Set proxy settings in application code

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (version 1.0 or higher)
- Scaleway account with API credentials configured
- Scaleway CLI installed and configured (optional, for easier resource management)

## Setup Instructions

### 1. Configure Variables

Before applying the configuration, you need to set your variables in the `terraform.tfvars` file:

```bash
# Copy the example file and edit it with your values
cp terraform.tfvars.example terraform.tfvars
```

Update the following values in `terraform.tfvars`:
- `project_id`: Your Scaleway Project ID
- `private_network_id`: The ID of your private network

### 2. Initialize Terraform

Initialize the working directory and download required providers:

```bash
terraform init
```

### 3. Review the Execution Plan

See what changes will be made before applying:

```bash
terraform plan
```

### 4. Apply the Configuration

Deploy the infrastructure:

```bash
terraform apply
```

Confirm the action when prompted by typing `yes`.

### 5. Destroy Resources (if needed)

When you no longer need the resources, you can destroy them:

```bash
terraform destroy
```

## Security Notes

- Never commit your `terraform.tfvars` file to version control as it contains sensitive information.
- The `hide_kubeconfig_output` variable is set to `false` by default to show the kubeconfig. Set it to `true` in production for security.
- Ensure your Scaleway API credentials have the appropriate permissions but follow the principle of least privilege.

## Multi-Tenancy Egress Proxy Demo Application

This repository includes a comprehensive demo application to showcase the egress proxy functionality in a multi-tenancy environment.

### Features

+- Interactive web interface to test connectivity
+- System information display (pod, node, namespace)
+- External IP address visibility test
+- Connectivity testing to external APIs (ipinfo.io, httpbin.org)
+- Real-time updates and error handling
+- Proper error handling and retry logic
+- Environment variable configuration for flexibility

### Architecture

+- **Backend**: Go web server with proper HTTP client configuration for proxy support
+- **Frontend**: Interactive HTML/CSS/JavaScript interface
+- **Containerization**: Docker container built from Go binary
+- **Registry**: Hosted in Scaleway registry at `rg.fr-par.scw.cloud/egress-multitenant-demo`
+- **Proxy Integration**: Configured with HTTP_PROXY and HTTPS_PROXY environment variables
+- **RBAC**: Dedicated service account with minimal required permissions
+- **Network Security**: NetworkPolicy restricting traffic to necessary endpoints

### Application Components

The application consists of:
- **Go server** (`app/egress-multitenant-demo/src/main.go`): Handles HTTP requests and external API calls through the proxy
- **Static assets** (`app/egress-multitenant-demo/static/`): HTML, CSS, and JavaScript for the user interface
- **Dockerfile**: Multi-stage build process creating a lightweight container
- **Makefile**: Simplifies build, push, and deployment processes

### Building and Deploying

The application is built and deployed using the following process:

1. **Build the Docker image**:
   ```bash
   cd app/egress-multitenant-demo
   make build
   ```
   
2. **Push to Scaleway registry**:
   ```bash
   make push
   # This pushes to rg.fr-par.scw.cloud/egress-multitenant-demo/egress-multitenant-demo:latest
   ```
   
3. **Deploy to Kubernetes**:
   ```bash
   make deploy
   # This applies the manifests through Flux CD
   ```

### Testing the Demo

1. Ensure the application is deployed:
   ```bash
   kubectl get pods -n client-a-demo
   ```

2. Access the application through port forwarding:
   ```bash
   kubectl port-forward svc/egress-multitenant-demo -n client-a-demo 8080:80
   ```
   
3. Open http://localhost:8080 in your browser
   
4. Test the functionality:
   - Click "Test External IP" to verify traffic goes through the proxy
   - Click "Test ipinfo.io" and "Test httpbin.org" to test external API access
   - Check the system information section for pod details

The demo application confirms that:
- The pod is properly configured with proxy environment variables
- External connectivity works through the proxy
- The egress isolation is functioning correctly
- The containerized application is securely deployed with proper RBAC and network policies

### Security Considerations
 
The implementation follows security best practices:
 
- **RBAC**: Each client type has dedicated service accounts with least privilege
- **Network Policies**: Strict egress rules for both client types
- **Node Isolation**: Taints and node selectors prevent cross-pool scheduling
- **Separation of Concerns**: Complete isolation between different client types
- **Auditability**: All egress traffic is trackable through either proxy logs or Load Balancer metrics
 
For production environments, consider:
- Authentication for web interfaces
- Rate limiting for external API calls
- Regular security audits and penetration testing
- Monitoring and alerting for security events
- Regular patching of base images and dependencies

The application implements security best practices:
- **RBAC**: Dedicated ServiceAccount with minimal required permissions
- **Network Policy**: Restricts egress traffic to only necessary endpoints
- **Lightweight Image**: Multi-stage Docker build creates a small, secure container
- **Proper Error Handling**: Graceful degradation when external services are unavailable

For production environments, consider enhancing security with:
- Authentication and authorization for web interfaces
- Rate limiting for external API calls
- Regular security audits and penetration testing
- Monitoring and alerting for security events
- Regular patching of base images and dependencies

## 📌 Operational Notes
## Working with Your Kubernetes Cluster

Once your infrastructure is deployed, you can interact with your Kubernetes cluster using kubectl. Here are essential commands:

### 1. Configure kubectl

First, configure kubectl to use your generated kubeconfig:

```bash
# Use the generated kubeconfig
export KUBECONFIG=./kubeconfig.yaml

# Verify connectivity
kubectl cluster-info

# View cluster nodes
kubectl get nodes

# View cluster configuration
kubectl config view
```

### 2. Basic Resource Management

Common commands for viewing and managing cluster resources:

```bash
# Get cluster information
kubectl cluster-info

# List all nodes
kubectl get nodes

# List all pods in all namespaces
kubectl get pods --all-namespaces

# List pods in current namespace
kubectl get pods

# List services
kubectl get services

# List deployments
kubectl get deployments

# List namespaces
kubectl get namespaces

# Get detailed information about a resource
kubectl describe pod <pod-name>
kubectl describe service <service-name>
```

### 3. Working with Deployments

Manage your applications with deployment commands:

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx

# Scale a deployment
kubectl scale deployment/nginx --replicas=3

# Update deployment image
kubectl set image deployment/nginx nginx=nginx:1.21

# Rollback to previous version
kubectl rollout undo deployment/nginx

# Check rollout status
kubectl rollout status deployment/nginx

# View deployment history
kubectl rollout history deployment/nginx
```

### 4. Accessing Applications

Expose and access your applications:

```bash
# Create a service to expose a deployment
kubectl expose deployment/nginx --port=80 --type=LoadBalancer

# Get service information (including external IP)
kubectl get services

# Port forward to access application locally
kubectl port-forward service/nginx 8080:80

# Get service endpoints
kubectl get endpoints
```

### 5. Monitoring and Logs

Monitor your cluster and view application logs:

```bash
# View pod logs
kubectl logs <pod-name>

# Follow pod logs (like tail -f)
kubectl logs -f <pod-name>

# Get logs from previous container instance
kubectl logs <pod-name> --previous

# View system-wide events
kubectl get events --sort-by=.metadata.creationTimestamp

# Monitor resource usage
kubectl top nodes
kubectl top pods
```

### 6. Troubleshooting

Essential commands for debugging issues:

```bash
# Get detailed information about a pod
kubectl describe pod <pod-name>

# Execute command in a running container
kubectl exec -it <pod-name> -- /bin/sh

# Copy files to/from containers
kubectl cp <namespace>/<pod>:/path/to/file /local/path
kubectl cp /local/path <namespace>/<pod>:/path/to/file

# View current context
kubectl config current-context

# Switch between contexts (if you have multiple)
kubectl config use-context <context-name>

# Debug network issues
kubectl run test-pod --image=alpine --restart=Never --rm -it -- sh
```

### 7. Configuration Management

Work with configuration files:

```bash
# Apply configuration from file
kubectl apply -f deployment.yaml

# Apply configuration from directory
kubectl apply -f ./manifests/

# Delete resources defined in file
kubectl delete -f deployment.yaml

# Create secrets
kubectl create secret generic db-password --from-literal=password=mypassword

# View secrets (note: values are base64 encoded)
kubectl get secrets
kubectl get secret db-password -o yaml
```

### 8. Namespace Operations

Work with Kubernetes namespaces:

```bash
# List all namespaces
kubectl get namespaces

# Create a namespace
kubectl create namespace staging

# Apply configuration to specific namespace
kubectl apply -f deployment.yaml -n staging

# Get resources in specific namespace
kubectl get pods -n staging

# Set default namespace for current context
kubectl config set-context --current --namespace=staging
```

### Useful Aliases

Consider adding these aliases to your shell configuration:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias kaf='kubectl apply -f'

# Common combinations
alias kga='kubectl get all'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods'
```

After applying your Terraform configuration, the `kubeconfig.yaml` file will be generated automatically, allowing you to immediately start using these kubectl commands to manage your Scaleway Kubernetes cluster.