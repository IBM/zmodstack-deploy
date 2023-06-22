#list all nodes
oc get nodes --kubeconfig /home/ec2-user/.kube/config
​
#check for certs expiry
oc -n openshift-kube-apiserver-operator get secret kube-apiserver-to-kubelet-signer -o jsonpath='{.metadata.annotations.auth\.openshift\.io/certificate-not-after}' --kubeconfig /home/ec2-user/.kube/config
​
#shutdown
for node in $(oc get nodes --kubeconfig /home/ec2-user/.kube/config -o jsonpath='{.items[*].metadata.name}'); do oc debug node/${node} --kubeconfig /home/ec2-user/.kube/config -- chroot /host shutdown -h 1; done