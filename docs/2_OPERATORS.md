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

## Installing OpenDataHub Operator

OpenDataHub is a blueprint for building an AI and Machine Learning (ML) platform on top of OpenShift.

To install the OpenDataHub operator, follow these instructions:

1. Create the namespace for OpenDataHub if it does not already exist:
   ```
   oc create ns opendatahub
   ```
2. Apply the OpenDataHub operator subscription:
   ```
   oc create -f manifests/opendatahub.yaml
   ```
3. Wait for the OpenDataHub operator subscription to be ready:
   ```
   oc wait -n openshift-operators subscription/opendatahub-operator --for=jsonpath='{.status.state}'=AtLatestKnown --timeout=180s
   ```

  
redhat-ods-monitoring-core-resource-limits
redhat-ods-monitoring
redhat-ods-applications-core-resource-limits
redhat-ods-applications
rhods-notebooks-core-resource-limits
rhods-notebooks




.PHONY: install-nfd-operator
install-nfd-operator: ## Install NFD operator ( Node Feature Discovery )
	@echo -e "\n==> Installing NFD Operator \n"
	-oc create ns openshift-nfd
	oc create -f contrib/configuration/nfd-operator-subscription.yaml
	@echo -e "\n==> Creating default NodeFeatureDiscovery CR \n"
	@while [[ -z $$(oc get customresourcedefinition nodefeaturediscoveries.nfd.openshift.io) ]]; do echo "."; sleep 10; done
	@while [[ -z $$(oc get csv -n openshift-nfd --selector operators.coreos.com/nfd.openshift-nfd) ]]; do echo "."; sleep 10; done
	oc get csv -n openshift-nfd --selector operators.coreos.com/nfd.openshift-nfd -ojsonpath={.items[0].metadata.annotations.alm-examples} | jq '.[] | select(.kind=="NodeFeatureDiscovery")' | oc apply -f -


.PHONY: install-nvidia-operator
install-nvidia-operator: ## Install nvidia operator
	@echo -e "\n==> Installing nvidia Operator \n"
	-oc create ns nvidia-gpu-operator
	oc create -f contrib/configuration/nvidia-operator-subscription.yaml
	@echo -e "\n==> Creating default ClusterPolicy CR \n"
	@while [[ -z $$(oc get customresourcedefinition clusterpolicies.nvidia.com) ]]; do echo "."; sleep 10; done
	@while [[ -z $$(oc get csv -n nvidia-gpu-operator --selector operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator) ]]; do echo "."; sleep 10; done
	oc get csv -n nvidia-gpu-operator --selector operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator -ojsonpath={.items[0].metadata.annotations.alm-examples} | jq .[] | oc apply -f -


##@ general
.PHONY: install-opendatahub-operator
install-opendatahub-operator: ## Install OpenDataHub operator
	@echo -e "\n==> Installing OpenDataHub Operator \n"
	-oc create ns opendatahub
	oc create -f contrib/configuration/opendatahub-operator-subscription.yaml
	@echo Waiting for opendatahub-operator Subscription to be ready
	oc wait -n openshift-operators subscription/opendatahub-operator --for=jsonpath='{.status.state}'=AtLatestKnown --timeout=180s