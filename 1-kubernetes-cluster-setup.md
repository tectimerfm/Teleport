# Kubernetes Cluster Setup with kubeadm and Flannel

## 1. Reference Documentation

- [Creating a Kubernetes cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [kubeadm cluster setup guide](https://kubeadm.org/create-a-kubernetes-cluster/)

## 2. Initialize the Control Plane

Run the following command on the control-plane node:

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket=unix:///run/containerd/containerd.sock
```

The `10.244.0.0/16` network is the default pod network used by Flannel.

## 3. Configure kubectl for a Non-Root User

Run these commands on the control-plane node:

```bash
mkdir -p "$HOME/.kube"

sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
```

Verify access to the cluster:

```bash
kubectl get nodes
```

## 4. Install the Flannel CNI

Flannel establishes pod network communication between the cluster nodes.

Reference:

- [Flannel deployment documentation](https://github.com/flannel-io/flannel#deploying-flannel-manually)

Install Flannel from the control-plane node:

```bash
kubectl apply -f \
  https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Check the Flannel pods:

```bash
kubectl get pods -n kube-flannel
```

## 5. Join Worker Nodes to the Cluster

Run the `kubeadm join` command generated during `kubeadm init` on each worker node:

```bash
sudo kubeadm join 172.31.14.198:6443 \
  --token hdbks4.2hdsq6nijjbd99ty \
  --discovery-token-ca-cert-hash \
  sha256:ee5ac3271abc3431f84b6aa8c03bb9460d408cc569d7a69d4c9827335f11504b
```

If the join command or token expires, generate a new one on the control-plane node:

```bash
sudo kubeadm token create --print-join-command
```

## 6. Validate the Cluster

After joining the worker nodes, run this command on the control-plane node:

```bash
kubectl get nodes -o wide
```

All nodes should eventually display the `Ready` status.

> **Security note:** kubeadm tokens should be treated as sensitive information. If the token shown above belongs to an active cluster, invalidate it and generate a new one.
