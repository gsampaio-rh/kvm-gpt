# Operator Installation Guide

This guide outlines the steps to install the Node Feature Discovery (NFD), NVIDIA GPU, and OpenDataHub operators on your OpenShift cluster.

## Installing NFD Operator

The Node Feature Discovery (NFD) Operator facilitates the discovery of hardware features and capabilities in an OpenShift cluster.

To install the NFD operator, follow these steps:

1. Create the namespace for the NFD operator if it does not already exist:

    ```sh
    oc create ns openshift-nfd
    ```

2. Apply the NFD operator subscription:

    ```sh
    oc create -f manifests/nfd.yaml
    ```

3. Wait for the Custom Resource Definition (CRD) to become available and then create the default NodeFeatureDiscovery custom resource (CR):

    ```sh
    while [[ -z $(oc get customresourcedefinition nodefeaturediscoveries.nfd.openshift.io) ]]; do echo "."; sleep 10; done
    while [[ -z $(oc get csv -n openshift-nfd --selector operators.coreos.com/nfd.openshift-nfd) ]]; do echo "."; sleep 10; done
    oc get csv -n openshift-nfd --selector operators.coreos.com/nfd.openshift-nfd -ojsonpath={.items[0].metadata.annotations.alm-examples} | jq '.[] | select(.kind=="NodeFeatureDiscovery")' | oc apply -f -
    ```

## Installing NVIDIA GPU Operator

The NVIDIA GPU Operator enables the deployment and management of GPU-accelerated resources in an OpenShift cluster.

To install the NVIDIA GPU operator, execute the following:

1. Create the namespace for the NVIDIA GPU operator if it does not already exist:

   ```sh
   oc create ns nvidia-gpu-operator
   ```

2. Apply the NVIDIA operator subscription:

   ```sh
   oc create -f manifests/nvidia.yaml
   ```

3. After the CRD becomes available, create the default ClusterPolicy CR:

   ```sh
   while [[ -z $(oc get customresourcedefinition clusterpolicies.nvidia.com) ]]; do echo "."; sleep 10; done
   while [[ -z $(oc get csv -n nvidia-gpu-operator --selector operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator) ]]; do echo "."; sleep 10; done
   oc get csv -n nvidia-gpu-operator --selector operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator -ojsonpath={.items[0].metadata.annotations.alm-examples} | jq .[] | oc apply -f -
   ```

## Installing Red Hat OpenShift Data Science Operator

Red Hat OpenShift Data Science provides a managed cloud service for data scientists and developers to build, develop, and deploy AI/ML models on OpenShift.

To install the Red Hat OpenShift Data Science operator, follow these instructions:

1. **Create the Namespace**: Ensure the namespace for the Red Hat OpenShift Data Science operator exists:

    ```sh
    oc create ns redhat-ods-operator
    ```

2. **Apply the Operator Subscription**: Apply the subscription YAML to subscribe to the operator:

    ```sh
    oc create -f manifests/rhods.yaml
    ```

3. **Wait for the Subscription to be Ready**: Wait until the operator subscription is fully ready:

    ```sh
    oc wait -n openshift-operators subscription/rhods-operator --for=jsonpath='{.status.state}'=AtLatestKnown --timeout=180s
    ```

    This concludes the installation of the Red Hat OpenShift Data Science Operator.

## Checking and Deleting Specified Limit Ranges

Certain limit ranges might interfere with the proper operation of Red Hat OpenShift Data Science. To check for and delete these limit ranges, follow these steps:

1. **Define Limit Ranges to Check and Delete**: Identify the limit ranges that may need to be deleted:

    - `redhat-ods-monitoring-core-resource-limits` in namespace `redhat-ods-monitoring`
    - `redhat-ods-applications-core-resource-limits` in namespace `redhat-ods-applications`
    - `rhods-notebooks-core-resource-limits` in namespace `rhods-notebooks`

2. **Check and Delete Limit Ranges**:

    Use the following commands to check for each limit range and delete it if found:

    ```sh
    # Check and delete limit range in redhat-ods-monitoring
    if oc get limitrange redhat-ods-monitoring-core-resource-limits -n redhat-ods-monitoring &> /dev/null; then
        oc delete limitrange redhat-ods-monitoring-core-resource-limits -n redhat-ods-monitoring
    fi

    # Check and delete limit range in redhat-ods-applications
    if oc get limitrange redhat-ods-applications-core-resource-limits -n redhat-ods-applications &> /dev/null; then
        oc delete limitrange redhat-ods-applications-core-resource-limits -n redhat-ods-applications
    fi

    # Check and delete limit range in rhods-notebooks
    if oc get limitrange rhods-notebooks-core-resource-limits -n rhods-notebooks &> /dev/null; then
        oc delete limitrange rhods-notebooks-core-resource-limits -n rhods-notebooks
    fi
    ```

This process ensures that any limit ranges that could interfere with Red Hat OpenShift Data Science are removed.