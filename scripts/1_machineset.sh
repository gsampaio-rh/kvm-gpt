#!/bin/bash

# Display options for machine types
echo "Select the type of machine for the GPU MachineSet:"
echo "1) p3.2xlarge    - 1 GPU, 16 CPUs, 61GiB Memory"
echo "2) p3.8xlarge    - 4 GPUs, 64 CPUs, 244GiB Memory"
echo "3) p3.16xlarge   - 8 GPUs, 128 CPUs, 488GiB Memory"
echo "4) p3dn.24xlarge - 8 GPUs, 256 CPUs, 768GiB Memory"
read -p "Enter the number of your choice (1-4): " choice

# Set MACHINE_TYPE based on user selection
case $choice in
    1) MACHINE_TYPE="p3.2xlarge";;
    2) MACHINE_TYPE="p3.8xlarge";;
    3) MACHINE_TYPE="p3.16xlarge";;
    4) MACHINE_TYPE="p3dn.24xlarge";;
    *) echo "Invalid selection. Exiting script."; exit 1;;
esac

echo "You selected: $MACHINE_TYPE"

# List all MachineSets in the openshift-machine-api namespace
echo "Listing all MachineSets:"
oc get machinesets -n openshift-machine-api

# Capture the first MachineSet name
MACHINESET_NAME=$(oc get machinesets -n openshift-machine-api | awk 'NR==2{print $1}')
echo "Using MachineSet: $MACHINESET_NAME"

# Export the MachineSet configuration
oc get machineset $MACHINESET_NAME -n openshift-machine-api -o json > machine_set_gpu.json

# Use jq to edit the file for GPU configuration
NEW_NAME=$(jq -r '.metadata.name + "-gpu"' machine_set_gpu.json)
jq '.metadata.name = $newName |
    .spec.selector.matchLabels."machine.openshift.io/cluster-api-machineset" = $newName |
    .spec.template.metadata.labels."machine.openshift.io/cluster-api-machineset" = $newName |
    .spec.template.spec.providerSpec.value.instanceType = "'$MACHINE_TYPE'"' \
    --arg newName "$NEW_NAME" machine_set_gpu.json > temp.json && mv temp.json machine_set_gpu.json

# Apply the updated MachineSet configuration
oc apply -f machine_set_gpu.json

# Wait a bit for the MachineSet to be processed
echo "Waiting for MachineSet to be created..."
sleep 10

# Validate the GPU MachineSet Creation
echo "Validating the GPU MachineSet creation and machines status:"
GPU_MACHINES=$(oc get machines -n openshift-machine-api | grep gpu)

if [[ ! -z "$GPU_MACHINES" ]]; then
    echo "GPU Machine(s) found:"
    echo "$GPU_MACHINES"
    echo "Detailing each GPU machine's status:"
    echo "$GPU_MACHINES" | while IFS= read -r line; do
        MACHINE_NAME=$(echo $line | awk '{print $1}')
        PHASE=$(echo $line | awk '{print $2}')
        TYPE=$(echo $line | awk '{print $3}')
        REGION=$(echo $line | awk '{print $4}')
        ZONE=$(echo $line | awk '{print $5}')
        AGE=$(echo $line | awk '{print $6}')

        echo "Machine Name: $MACHINE_NAME"
        echo "Phase: $PHASE, Type: $TYPE, Region: $REGION, Zone: $ZONE, Age: $AGE"
        echo "----------------------"
    done
else
    echo "No GPU Machine found. Please check the creation steps."
fi

# Prompt for deleting the JSON file after operations are complete
read -p "Do you want to delete the machine_set_gpu.json file? (y/n): " delete_confirm
if [[ $delete_confirm == [Yy] ]]; then
    echo "Deleting machine_set_gpu.json file..."
    rm -f machine_set_gpu.json
    echo "File deleted."
else
    echo "Keeping the machine_set_gpu.json file."
fi
