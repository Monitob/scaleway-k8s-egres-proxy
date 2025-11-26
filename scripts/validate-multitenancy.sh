#!/bin/bash

# validate-multitenancy.sh
# Script to validate the multi-tenancy configuration

echo "Validating multi-tenancy configuration..."
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Kubernetes cluster connection verified"

# Function to check for specific label
check_label() {
    local label=$1
    local count=$(kubectl get nodes -l $label --no-headers 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
        echo "✅ Found $count node(s) with label: $label"
        return 0
    else
        echo "❌ No nodes found with label: $label"
        return 1
    fi
}

# Function to check for specific taint
check_taint() {
    local taint=$1
    local count=$(kubectl describe nodes 2>/dev/null | grep -c "$taint") || true
    if [ $count -gt 0 ]; then
        echo "✅ Found taint on nodes: $taint"
        return 0
    else
        echo "❌ No nodes found with taint: $taint"
        return 1
    fi
}

# Validate client-type-a configuration
echo ""
echo "Validating Client Type A Configuration..."
echo "----------------------------------------"

check_label "pool=client-type-a-pool"
check_taint "node-role.kubernetes.io/client-a=dedicated:NoSchedule"

# Validate client-type-b configuration
echo ""
echo "Validating Client Type B Configuration..."
echo "----------------------------------------"

check_label "pool=client-type-b-pool"
check_taint "node-role.kubernetes.io/client-b=dedicated:NoSchedule"

# Check namespace existence
echo ""
echo "Validating Namespaces..."
echo "------------------------"

for ns in client-type-a client-type-b; do
    if kubectl get namespace $ns &> /dev/null; then
        echo "✅ Namespace $ns exists"
    else
        echo "❌ Namespace $ns does not exist"
    fi
done

# Final status
echo ""
echo "Validation complete!"
```
</tool_call>
