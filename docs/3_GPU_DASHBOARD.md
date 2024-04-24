# Enabling the GPU Monitoring Dashboard

The GPU Operator exposes GPU telemetry for Prometheus by using the NVIDIA DCGM Exporter. These metrics can be visualized using a monitoring dashboard based on Grafana.

This guide walks you through adding the dashboard to the Observe section of the OpenShift Container Platform web console.

## Prerequisites

- Your cluster uses OpenShift Container Platform 4.10 or higher.
- You have access to the cluster as a user with the cluster-admin cluster role.
- Install Helm

## Configuring the NVIDIA DCGM Exporter Dashboard

1. First, download the latest NVIDIA DCGM Exporter Dashboard from the DCGM Exporter repository on GitHub:

    ```sh
    curl -LfO https://github.com/NVIDIA/dcgm-exporter/raw/main/grafana/dcgm-exporter-dashboard.json
    ```

2. Create a config map from the downloaded file in the `openshift-config-managed` namespace:

    ```sh
    oc create configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed --from-file=dcgm-exporter-dashboard.json
    ```

3. Label the config map to expose the dashboard in the Administrator perspective of the web console:

    ```sh
    oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/dashboard=true"
    ```

*Optionally, label the config map to also expose the dashboard in the Developer perspective of the web console:*

```sh
oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/odc-dashboard=true"
```

### Verify the Labels

View the created resource and verify the labels:

```sh
oc -n openshift-config-managed get cm nvidia-dcgm-exporter-dashboard --show-labels
```

### Viewing GPU Metrics

In the OpenShift Container Platform web console from the side menu, switch to the **Administrator** perspective, then navigate to **Observe > Dashboards** and select **NVIDIA DCGM Exporter Dashboard** from the Dashboard list.

If the dashboard was added to the Developer perspective, in the OpenShift Container Platform web console from the side menu, switch to the **Developer** perspective, navigate to **Observe > Dashboard** and select **NVIDIA DCGM Exporter Dashboard** from the Dashboard list.

The NVIDIA DCGM Exporter Dashboard displays GPU-related graphs, allowing you to monitor the performance and utilization of GPUs within your cluster.

## Enable the NVIDIA GPU Operator usage information

1. **Add the Helm repo**:

    ```sh
    helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu
    ```

2. **Update the repo**:

    ```sh
    helm repo update
    ```

3. **Install the Helm chart** in the default NVIDIA GPU Operator namespace:

    ```sh
    helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu
    ```

    After installation, you should see output similar to:

    ```sh
    NAME: console-plugin-nvidia-gpu
    LAST DEPLOYED: Thu Apr 14 09:35:36 2022
    NAMESPACE: nvidia-gpu-operator
    STATUS: deployed
    REVISION: 1
    ```

4. **View the Console Plugin NVIDIA GPU deployed resources**:

    ```sh
    oc -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu
    ```

5. **Enable the plugin** by running:

    ```sh
    kubectl patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
    ```

6. **View the deployed resources**:

    ```sh
    kubectl -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu
    ```

7. **Verify the plugins field** is specified:

    ```sh
    oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}"
    ```

    A. If it is not specified, then enable the plugin with:

    ```sh
    oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge
    ```

    B. If it is specified, you can add the plugin with:

    ```sh
    oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
    ```

In the OpenShift Container Platform web console from the side menu, navigate to **Home > Overview** to see the Cluster utilization window now displaying the GPU-related graphs.

### The NVIDIA GPU Operator Dashboards

The following table provides a brief description of the displayed dashboards:

| Dashboard              | Description                                                   |
|------------------------|---------------------------------------------------------------|
| GPU                    | Number of available GPUs.                                     |
| GPU Power Usage        | Power usage in watts for each GPU.                            |
| GPU Encoder/Decoder    | Percentage of GPU workload dedicated to video encoding and decoding. |