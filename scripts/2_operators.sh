#!/bin/bash

echo "Starting the installation of NFD and NVIDIA GPU operators on OpenShift cluster..."

# Navigate to the project root directory if the script is not executed from there
cd "$(dirname "$0")/.."

# Install NFD Operator
echo "Installing NFD Operator..."
oc create ns openshift-nfd
oc create -f manifests/nfd.yaml

echo "Waiting for NFD Operator's Custom Resource Definition (CRD) to become available..."
while [[ -z $(oc get customresourcedefinition nodefeaturediscoveries.nfd.openshift.io) ]]; do echo "Waiting for NFD CRD..."; sleep 10; done

echo "Creating the default NodeFeatureDiscovery custom resource (CR)..."
while [[ -z $(oc get csv -n openshift-nfd --selector operators.coreos.com/nfd.openshift-nfd) ]]; do echo "Waiting for NFD CSV..."; sleep 10; done
oc get csv -n openshift-nfd --selector operators.coreos.com/nfd.openshift-nfd -ojsonpath='{.items[0].metadata.annotations.alm-examples}' | jq '.[] | select(.kind=="NodeFeatureDiscovery")' | oc apply -f -

# Install NVIDIA GPU Operator
echo "Installing NVIDIA GPU Operator..."
oc create ns nvidia-gpu-operator
oc create -f manifests/nvidia.yaml

echo "Waiting for NVIDIA GPU Operator's Custom Resource Definition (CRD) to become available..."
while [[ -z $(oc get customresourcedefinition clusterpolicies.nvidia.com) ]]; do echo "Waiting for NVIDIA GPU CRD..."; sleep 10; done

echo "Creating the default ClusterPolicy custom resource..."
while [[ -z $(oc get csv -n nvidia-gpu-operator --selector operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator) ]]; do echo "Waiting for NVIDIA GPU CSV..."; sleep 10; done
oc get csv -n nvidia-gpu-operator --selector operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator -ojsonpath='{.items[0].metadata.annotations.alm-examples}' | jq .[] | oc apply -f -

echo "Installation of NFD and NVIDIA GPU operators completed."

# Verifying NFD Operation
echo "Verifying NFD Operation..."

echo "Checking nodes for NVIDIA GPU hardware detection by NFD..."

# Using oc describe to filter nodes and pci labels, excluding master nodes
OC_DESCRIBE_OUTPUT=$(oc describe node | egrep 'Roles|pci' | grep -v master)

# Check for the presence of NVIDIA GPUs
if echo "$OC_DESCRIBE_OUTPUT" | grep -q 'feature.node.kubernetes.io/pci-10de.present=true'; then
    echo "NVIDIA GPU detected by NFD on the following nodes:"
    echo "$OC_DESCRIBE_OUTPUT" | grep 'feature.node.kubernetes.io/pci-10de.present=true' -B 1
else
    echo "No NVIDIA GPU detected by NFD on any worker nodes."
fi

echo "Installing Red Hat OpenShift Data Science Operator..."

# Create namespace
oc create ns redhat-ods-operator

# Apply the Red Hat OpenShift Data Science operator subscription
oc create -f manifests/rhods.yaml

# Wait for the operator subscription to be ready
echo "Waiting for the Red Hat OpenShift Data Science operator subscription to be ready..."
oc wait -n openshift-operators subscription/rhods-operator --for=jsonpath='{.status.state}'=AtLatestKnown --timeout=180s

echo "Red Hat OpenShift Data Science Operator installation completed."

echo "Checking and deleting specified limit ranges..."

# Define an associative array with limit range names as keys and namespaces as values
declare -A limit_ranges=(
    ["redhat-ods-monitoring-core-resource-limits"]="redhat-ods-monitoring"
    ["redhat-ods-applications-core-resource-limits"]="redhat-ods-applications"
    ["rhods-notebooks-core-resource-limits"]="rhods-notebooks"
)

# Iterate over the associative array
for limit_range in "${!limit_ranges[@]}"; do
    ns="${limit_ranges[$limit_range]}"
    echo "Checking for the limit range '$limit_range' in namespace '$ns'..."
    
    # Check if the limit range exists
    if oc get limitrange "$limit_range" -n "$ns" &> /dev/null; then
        echo "Limit range '$limit_range' found in namespace '$ns'. Deleting..."
        oc delete limitrange "$limit_range" -n "$ns"
        echo "Limit range '$limit_range' deleted."
    else
        echo "Limit range '$limit_range' not found in namespace '$ns'."
    fi
done

echo "Limit range deletion process completed."

echo "Installing Red Hat OpenShift GitOps Operator..."

# Create namespace for GitOps if it doesn't already exist
oc create ns openshift-gitops

# Apply the Subscription to the cluster
oc create -f manifests/gitops.yaml

# Wait for the ClusterServiceVersion of the GitOps operator to be ready
echo "Waiting for the Red Hat OpenShift GitOps operator to be ready..."
oc wait -n openshift-gitops clusterserviceversion openshift-gitops-operator.v1.8.0 --for=condition=Ready --timeout=180s

echo "Red Hat OpenShift GitOps Operator installation completed."

echo "Verifying that all necessary GitOps components are operational..."

# Loop until all pods are in the Running state
while true; do
    # Get the status of all pods in the specified namespace
    PODS=$(oc get pods -n $NAMESPACE --field-selector=status.phase!=Running)
    
    # Check if any pods are not in the Running state
    if [[ -z "$PODS" ]]; then
        echo "All pods are in the Running state."
        break
    else
        echo "Waiting for all pods to be in Running state..."
        echo "$PODS"
        sleep 10
    fi
done

echo "GitOps components check completed."