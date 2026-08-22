#!/bin/bash
set -euxo pipefail

K8S_VERSION="v1.36"

# ------------------------------------------------------------
# Atualizar sistema
# ------------------------------------------------------------
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

apt-get install -y \
  ca-certificates \
  curl \
  gpg \
  containerd

# ------------------------------------------------------------
# Desabilitar SWAP
# ------------------------------------------------------------
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# ------------------------------------------------------------
# Kernel modules para Kubernetes
# ------------------------------------------------------------
cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# ------------------------------------------------------------
# Networking / sysctl
# ------------------------------------------------------------
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# ------------------------------------------------------------
# Configurar containerd
# ------------------------------------------------------------
mkdir -p /etc/containerd

containerd config default > /etc/containerd/config.toml

# Garantir SystemdCgroup
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' \
  /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# ------------------------------------------------------------
# Kubernetes repository
# ------------------------------------------------------------
mkdir -p /etc/apt/keyrings

curl -fsSL \
  https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key \
  | gpg --dearmor \
  -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /
EOF

# ------------------------------------------------------------
# Instalar kubelet / kubeadm / kubectl
# ------------------------------------------------------------
apt-get update

apt-get install -y \
  kubelet \
  kubeadm \
  kubectl

apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# ------------------------------------------------------------
# Mostrar versões no log
# ------------------------------------------------------------
echo "========== Kubernetes installation =========="
kubeadm version
kubectl version --client
kubelet --version
containerd --version

touch /var/log/kubernetes-install-complete

echo "Kubernetes prerequisites installed successfully."
