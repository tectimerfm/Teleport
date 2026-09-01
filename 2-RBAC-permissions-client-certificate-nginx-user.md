# Configuring RBAC permissions using the `nginx` role with the necessary permissions to manage the `nginx` namespace, including creating the Kubernetes Client Certificate and Kubeconfig.

This guide configures RBAC permissions and creates a private key, requests a Kubernetes client certificate valid for 14 days, builds a dedicated kubeconfig, and verifies the user's RBAC permissions.

## 1. Official Documentation

- [Issue a Certificate for a Kubernetes API Client Using a CertificateSigningRequest](https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/)
- [CertificateSigningRequest v1 API reference](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/certificate-signing-request-v1/)


## 2. Create the namespace `nginx`

Create the default namespace `nginx`:

```bash
kubectl create ns nginx
```

## 3. Create the file nginx-rbac.yaml with the RBAC permissions and apply.

```bash
cat > nginx-rbac.yaml <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: nginx
  name: nginx-deployer
rules:

# Allow managing deployments
- apiGroups: ["apps"]
  resources:
    - deployments
  verbs:
    - get
    - list
    - watch
    - create
    - update
    - patch
    - delete

# Allows you to view ReplicaSets
- apiGroups: ["apps"]
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch

# Allows you to manage Services
- apiGroups: [""]
  resources:
    - services
  verbs:
    - get
    - list
    - watch
    - create
    - update
    - patch
    - delete

# Allows you to view Pods
- apiGroups: [""]
  resources:
    - pods
  verbs:
    - get
    - list
    - watch
    
# Allows Teleport exec
- apiGroups: [""]
  resources:
    - pods/exec
  verbs:
    - get
    - create

# Allows you to view logs
- apiGroups: [""]
  resources:
    - pods/log
  verbs:
    - get
    
# Ingress
- apiGroups:
    - networking.k8s.io
  resources:
    - ingresses
  verbs:
    - get
    - list
    - watch
    - create
    - update
    - patch
    - delete
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: nginx
  name: nginx-deployer-binding
subjects:
- kind: User
  name: nginx-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: nginx-deployer
  apiGroup: rbac.authorization.k8s.io
EOF
```

Apply the RBCA via `nginx-rbac.yaml`:

```bash
kubectl apply -f nginx-rbac.yaml
```

## 4. Create the User's Private Key

Create a working directory and generate a 3072-bit RSA private key:

```bash
mkdir -p "$HOME/nginx-user"
cd "$HOME/nginx-user"

openssl genrsa -out nginx-user.key 3072
chmod 600 nginx-user.key
```

## 5. Create the Certificate Signing Request

Create a Certificate Signing Request (CSR) with `nginx-user` as the Common Name (CN):

```bash
openssl req \
  -new \
  -key nginx-user.key \
  -out nginx-user.csr \
  -subj "/CN=nginx-user"
```

Kubernetes uses the certificate's CN as the username during authentication.

## 6. Create the Kubernetes CertificateSigningRequest

Convert the CSR to a single-line base64 string:

```bash
CSR="$(base64 < nginx-user.csr | tr -d '\n')"
```

Create a Kubernetes `CertificateSigningRequest` requesting a certificate lifetime of 14 days:

```bash
cat > nginx-user-csr.yaml <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: nginx-user
spec:
  request: ${CSR}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 1209600
  usages:
    - client auth
EOF
```

The value `1209600` represents 14 days in seconds.

Submit the request and check its status:

```bash
kubectl apply -f nginx-user-csr.yaml
kubectl get csr nginx-user
```

## 7. Approve the Certificate Request

An authorized cluster administrator must approve the request:

```bash
kubectl certificate approve nginx-user
```

Confirm that it has been approved and issued:

```bash
kubectl get csr nginx-user
```

## 8. Extract the Issued Certificate

Extract and decode the certificate returned by Kubernetes:

```bash
kubectl get csr nginx-user \
  -o jsonpath='{.status.certificate}' \
  | base64 -d > nginx-user.crt
```

The working directory should now contain:

- `nginx-user.key`: private key
- `nginx-user.csr`: local certificate request
- `nginx-user.crt`: certificate issued by Kubernetes
- `nginx-user-csr.yaml`: Kubernetes CSR manifest

Inspect the certificate:

```bash
openssl x509 \
  -in nginx-user.crt \
  -noout \
  -subject \
  -issuer \
  -dates
```

Check the `notBefore` and `notAfter` values to confirm the actual validity period granted by the cluster.

## 9. Create a Dedicated Kubeconfig

Create a separate kubeconfig for `nginx-user` using the certificate and private key generated above.

Display the API Server endpoint configured in the administrator's current kubeconfig:

```bash
kubectl config view \
  --minify \
  -o jsonpath='{.clusters[0].cluster.server}'; echo
```

Set the public IP address of the control-plane node:

```bash
PUBLIC_IP="54.183.216.118"
API_SERVER="https://${PUBLIC_IP}:6443"
```

Create the cluster entry:

```bash
kubectl config \
  --kubeconfig=nginx-user.kubeconfig \
  set-cluster kubernetes \
  --server="$API_SERVER" \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true
```

Configure the user credentials:

```bash
kubectl config \
  --kubeconfig=nginx-user.kubeconfig \
  set-credentials nginx-user \
  --client-certificate=nginx-user.crt \
  --client-key=nginx-user.key \
  --embed-certs=true
```

Create a context that uses the `nginx` namespace by default:

```bash
kubectl config \
  --kubeconfig=nginx-user.kubeconfig \
  set-context nginx-user@kubernetes \
  --cluster=kubernetes \
  --namespace=nginx \
  --user=nginx-user
```

Activate the context:

```bash
kubectl config \
  --kubeconfig=nginx-user.kubeconfig \
  use-context nginx-user@kubernetes
```

> **Important:** The Kubernetes API Server certificate must contain the public IP address in its Subject Alternative Names (SANs). TCP port `6443` must also be reachable from the client and restricted to trusted source IP addresses.

## 10. Copy the Kubeconfig to the Client Computer

Run the following commands on the client computer that will access the cluster:

```bash
mkdir -p "$HOME/.kube"

scp -i "rob_key.pem" \
  ubuntu@54.183.216.118:/home/ubuntu/nginx-user/nginx-user.kubeconfig \
  "$HOME/.kube/nginx-user"

chmod 600 "$HOME/.kube/nginx-user"
```

## 11. Test Cluster Access

Test whether the user can list pods in the `nginx` namespace:

```bash
kubectl \
  --kubeconfig="$HOME/.kube/nginx-user" \
  get pods -n nginx
```

Test whether RBAC allows the user to create Deployments:

```bash
kubectl \
  --kubeconfig="$HOME/.kube/nginx-user" \
  auth can-i create deployments.apps -n nginx
```

Expected output when the required RBAC permission has been granted:

```text
yes
```

The certificate authenticates the identity `nginx-user`, but it does not grant permissions by itself. A `RoleBinding` or `ClusterRoleBinding` must associate this user with the appropriate Kubernetes RBAC role.

## 12. Security Recommendations

- Keep `nginx-user.key` private and never share it separately.
- Store the kubeconfig with file permissions set to `600`.
- Restrict access to TCP port `6443` in the AWS Security Group.
- Grant only the minimum RBAC permissions required by the user.
- Revoke access by deleting or changing the applicable RBAC binding. Deleting the CSR object does not invalidate an already issued certificate.
