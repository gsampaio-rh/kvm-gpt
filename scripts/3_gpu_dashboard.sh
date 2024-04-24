#!/bin/bash

# NVIDIA DCGM Exporter Dashboard

# Set the namespace where the ConfigMap will be created
NAMESPACE="openshift-config-managed"

echo "Downloading the NVIDIA DCGM Exporter Dashboard..."
curl -LfO https://github.com/NVIDIA/dcgm-exporter/raw/main/grafana/dcgm-exporter-dashboard.json

echo "Creating ConfigMap from the DCGM Exporter Dashboard JSON file..."
oc create configmap nvidia-dcgm-exporter-dashboard -n ${NAMESPACE} --from-file=dcgm-exporter-dashboard.json

echo "Labeling the ConfigMap to expose the dashboard in the Administrator perspective..."
oc label configmap nvidia-dcgm-exporter-dashboard -n ${NAMESPACE} "console.openshift.io/dashboard=true"

echo "Optionally labeling the ConfigMap to expose the dashboard in the Developer perspective..."
oc label configmap nvidia-dcgm-exporter-dashboard -n ${NAMESPACE} "console.openshift.io/odc-dashboard=true"

echo "Verifying the labels of the created ConfigMap..."
oc -n ${NAMESPACE} get cm nvidia-dcgm-exporter-dashboard --show-labels

echo "Cleanup: Removing the downloaded dashboard JSON file..."
rm -f dcgm-exporter-dashboard.json

echo "Configuration of the NVIDIA DCGM Exporter Dashboard is complete."

# NVIDIA GPU Console Plugin

echo "Adding the Helm repo for the NVIDIA GPU Console Plugin..."
helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu

echo "Updating the Helm repo..."
helm repo update

echo "Installing the Helm chart for the NVIDIA GPU Console Plugin in the nvidia-gpu-operator namespace..."
helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu

echo "Viewing the deployed resources for the Console Plugin NVIDIA GPU..."
kubectl -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu

echo "Enabling the Console Plugin NVIDIA GPU..."
kubectl patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json

echo "Verifying the deployed resources..."
oc -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu

echo "Verifying if the plugins field is specified in the console operator..."
PLUGIN_CHECK=$(oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}")

if [[ -z "$PLUGIN_CHECK" ]]; then
    echo "The plugins field is not specified. Enabling the console-plugin-nvidia-gpu plugin..."
    oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge
else
    echo "The plugins field is specified. Adding the console-plugin-nvidia-gpu plugin..."
    oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
fi

echo "GPU Operator Console Plugin setup completed."
