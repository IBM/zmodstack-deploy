#!/bin/bash

# Check if at least one parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <parameter>"
    echo "exactly one parameter needed!!"
    exit 1
fi

# Access the first parameter using $1
node="$1"


#cordon the node and wait untill the node is non-schedulable
# Function to check if a node is cordoned
is_node_cordoned() {
  node_name="$1"
  oc get nodes "$node_name" -o=jsonpath='{.spec.taints}' | grep -q 'NoSchedule'
}

# Cordon (drain) all nodes in the cluster
echo "Cordoning node: $node"
oc adm cordon "$node"

# Wait for all nodes to be cordoned
echo "Waiting for the node to be cordoned..."
while ! is_node_cordoned "$node"; do
    echo "Node $node is not cordoned yet. Waiting..."
    sleep 5
done
echo "Node $node is cordoned."

#drain all the node 
echo "Draining node: $node"
oc adm drain $node --delete-emptydir-data=true --ignore-daemonsets=true --grace-period=15 --disable-eviction --force

#restart all the nodes
echo "Cordoning node: $node"
#oc debug node/${node} --kubeconfig /home/ec2-user/.kube/config -- chroot /host reboot

#uncordon all the nodes 
echo "Cordoning node: $node"
oc adm uncordon "$node"