#!/bin/bash

#list all nodes
oc get nodes --show-labels --kubeconfig /home/ec2-user/.kube/config
echo "***********************"
echo "***********************"

echo 
#check for certs expiry
oc -n openshift-kube-apiserver-operator get secret kube-apiserver-to-kubelet-signer -o jsonpath='{.metadata.annotations.auth\.openshift\.io/certificate-not-after}' --kubeconfig /home/ec2-user/.kube/config
echo "***********************"
echo "***********************"

#cordon all the nodes and wait untill all nodes are non-schedulable
# Function to check if a node is cordoned
is_node_cordoned() {
  node_name="$1"
  oc get nodes "$node_name" -o=jsonpath='{.spec.taints}' | grep -q 'NoSchedule'
}

nodes=$(oc get nodes -o=jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')

# Cordon (drain) all nodes in the cluster
for node in $nodes; do
  echo "Cordoning node: $node"
  oc adm cordon "$node"
done

# Wait for all nodes to be cordoned
echo "Waiting for all nodes to be cordoned..."
while IFS= read -r node; do
  while ! is_node_cordoned "$node"; do
    echo "Node $node is not cordoned yet. Waiting..."
    sleep 5
  done
  echo "Node $node is cordoned."
done <<< "$nodes"

echo "All nodes are cordoned."
echo "***********************"

#drain all the node 
for node in $nodes; do
  echo "Draining node: $node"
  oc adm drain $node --delete-emptydir-data=true --ignore-daemonsets=true --grace-period=15 --disable-eviction --force
done

#restart all the nodes
for node in $nodes; do
  echo "Cordoning node: $node"
  oc debug node/${node} --kubeconfig /home/ec2-user/.kube/config -- chroot /host reboot
done
#wait untill restart

#uncordon all the nodes 
for node in $nodes; do
  echo "Cordoning node: $node"
  oc adm uncordon "$node"
done
