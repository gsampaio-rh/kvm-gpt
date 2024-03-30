# Machine Sets

## Steps

**Export Current MachineSet Configuration**
First, identify the name of an existing MachineSet you wish to clone for your GPU nodes. You can list all MachineSets in the `openshift-machine-api` namespace with:

```sh
oc get machinesets -n openshift-machine-api

# Capture the first MachineSet name
MACHINESET_NAME=$(oc get machinesets -n openshift-machine-api | awk 'NR==2{print $1}')
```

Choose an existing MachineSet from the list and export its configuration:

```sh
oc get machineset $MACHINESET_NAME -n openshift-machine-api -o json > machine_set_gpu.json
```

**Modify the MachineSet Configuration for GPU**
Edit the `machine_set_gpu.json` file to configure the MachineSet for GPU nodes:

- Change the `metadata:name` to a new name that includes "GPU" to easily identify it (e.g., cluster-gpu-worker).
- Update the `spec:selector:matchLabels:machine.openshift.io/cluster-api-machineset` to match the new name.
- Adjust `spec:template:metadata:labels:machine.openshift.io/cluster-api-machineset` likewise.
*Additionally, modify the instance type and any other relevant specifications to suit your GPU requirements based on your cloud provider's offerings.*

```sh
# Use jq to edit the file
NEW_NAME=$(jq -r '.metadata.name + "-gpu"' machine_set_gpu.json)
jq '.metadata.name = $newName |
    .spec.selector.matchLabels."machine.openshift.io/cluster-api-machineset" = $newName |
    .spec.template.metadata.labels."machine.openshift.io/cluster-api-machineset" = $newName' \
    --arg newName "$NEW_NAME" machine_set_gpu.json > temp.json && mv temp.json machine_set_gpu.json
```

**Create the GPU MachineSet**
Apply the updated MachineSet configuration to your cluster:

```sh
# Apply the updated MachineSet configuration
oc apply -f machine_set_gpu.json
```

**Validate the GPU MachineSet Creation**
Confirm the new MachineSet is created and is provisioning nodes:

```sh
oc get machinesets -n openshift-machine-api | grep gpu
```

**Validate the Machines in the GPU MachineSet**
After creating the GPU MachineSet, verify that the machines are correctly provisioned and in the expected state:
Confirm the new MachineSet is created and is provisioning nodes:

```sh
# List machines in the GPU MachineSet
oc get machines -n openshift-machine-api | grep $NEW_NAME
```

**Validate Nodes Attached to the GPU MachineSet**
Machines that are successfully provisioned should be attached to nodes within your OpenShift cluster. Validate that these nodes are operational and correctly labeled for GPU workloads:

```sh
# List nodes and filter by GPU label
oc get nodes -l <GPU_LABEL>
```

Replace <GPU_LABEL> with the specific label applied to your GPU nodes. This label varies based on how your cluster is configured to recognize GPU nodes. Common labels might include something like `node-role.kubernetes.io/gpu="true"` or a custom label indicating GPU capability.

These steps ensure that your GPU MachineSet is not only created but also that its machines are properly provisioned and associated nodes are correctly recognized and labeled in your cluster, ready for GPU workloads.
