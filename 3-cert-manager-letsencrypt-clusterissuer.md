# Configure cert-manager and a Let's Encrypt ClusterIssuer for NGINX Ingress + Nginx Ingress with Static nodePort

This guide installs cert-manager and configures a production Let's Encrypt `ClusterIssuer` that uses the HTTP-01 challenge through the NGINX Ingress Controller.

## Important Clarification

The Let's Encrypt certificate issued by cert-manager provides HTTPS for the NGINX website exposed through the Ingress Controller.

It is separate from the Kubernetes client certificate used by `nginx-user` to authenticate with the Kubernetes API. The `nginx-user` kubeconfig and RBAC permissions do not provide the cluster-wide privileges required to install cert-manager or create a `ClusterIssuer`.

## 1. Prerequisites

Before continuing, confirm that:

- The NGINX Ingress Controller is installed and operational.
- The IngressClass is named `nginx`.
- The public DNS record points to the external AWS Load Balancer used by the NGINX Ingress Controller.
- TCP ports `80` and `443` are reachable from the internet.
- You are using an administrator kubeconfig with sufficient cluster-wide permissions.

For this environment, the DNS record is managed through IONOS.

## 2. Official Documentation

- [Installing cert-manager with kubectl](https://cert-manager.io/docs/installation/kubectl/)
- [Issuing an ACME certificate using HTTP validation](https://cert-manager.io/docs/tutorials/acme/http-validation/)
- [cert-manager v1.21.1 release](https://github.com/cert-manager/cert-manager/releases/tag/v1.21.1)

## 3. Install cert-manager

Install cert-manager as a cluster administrator. Do not perform this installation using the restricted `nginx-deployer` Role.

```bash
kubectl apply -f \
  https://github.com/cert-manager/cert-manager/releases/download/v1.21.1/cert-manager.yaml
```

The installation manifest creates the cert-manager CustomResourceDefinitions and deploys its components in the `cert-manager` namespace.

## 4. Wait for cert-manager to Become Ready

Watch the cert-manager pods:

```bash
kubectl get pods -n cert-manager -w
```

Wait until the following components show the `Running` status and all containers are ready:

- `cert-manager`
- `cert-manager-cainjector`
- `cert-manager-webhook`

Press `Ctrl+C` after all pods are ready.

You can also confirm the deployments without watch mode:

```bash
kubectl get deployments -n cert-manager
```

## 5. Create the Production Let's Encrypt ClusterIssuer

Replace `<INSERT_YOUR_EMAIL_ADDRESS>` with a valid email address that you control. Let's Encrypt can use this address for important account and certificate notifications.

```bash
cat > letsencrypt-prod.yaml <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: <INSERT_YOUR_EMAIL_ADDRESS>
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
EOF
```

The `ingressClassName: nginx` setting instructs cert-manager to create temporary Ingress resources handled by the NGINX Ingress Controller during HTTP-01 validation. This is the recommended configuration for Ingress controllers that support `ingressClassName`, including ingress-nginx.

## 6. Apply the ClusterIssuer

```bash
kubectl apply -f letsencrypt-prod.yaml
```

## 7. Verify the ClusterIssuer

Check its status:

```bash
kubectl get clusterissuer letsencrypt-prod
```

The `READY` column should eventually display `True`.

For additional details and events, run:

```bash
kubectl describe clusterissuer letsencrypt-prod
```

You can also wait explicitly for the issuer to become ready:

```bash
kubectl wait \
  --for=condition=Ready \
  clusterissuer/letsencrypt-prod \
  --timeout=120s
```

## 8. Creating the Nginx Ingress with Static nodePort and issuing the SSL certificate for https://nginx.ninjadevops.co.uk/

Install Ingress-nginx (ingress-nginx-controller) as a cluster administrator. Do not perform this installation using the restricted `nginx-deployer` Role.

```bash
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/baremetal/deploy.yaml
```

Check its status:

```bash
kubectl get pods -n ingress-nginx -w
```

Therefore, we do not edit the `ingress-nginx-controller` service to pin the node ports to 30080 and 30443; this ensures they do not change during a new deployment, thereby avoiding a loss of connectivity with the AWS Load Balancer.

```bash
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```

In the spec.ports section, we explicitly specify:

```bash
spec:
  type: NodePort

  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: 30080

  - name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: 30443
```
After saving, confirm:

```bash
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```
The result must show:

```bash
80:30080/TCP,443:30443/TCP
```

Note: The following steps must be executed using the restricted `nginx-deployer` function, via the Kubeconfig created according to the tutorial below.

Reference:

- [Configuring RBAC permissions using the nginx role with the necessary permissions to manage the nginx namespace, including creating the Kubernetes Client Certificate and Kubeconfig.](https://github.com/tectimerfm/Teleport/blob/main/2-RBAC-permissions-client-certificate-nginx-user.md/)

A Kubernetes `Ingress` or `Certificate` resource must reference `letsencrypt-prod` and specify the required DNS name. For an Ingress resource, the usual annotation is:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

```bash
cat > nginx-ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  namespace: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - nginx.ninjadevops.co.uk
    secretName: nginx-tls
  rules:
  - host: nginx.ninjadevops.co.uk
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF
```

And apply with:

```bash
kubectl apply -f nginx-ingress.yaml
```

The Ingress must also contain a `tls` section with the website hostname and the name of the Secret where cert-manager will store the certificate.

## 9. HTTP-01 Validation Requirements

During certificate issuance, cert-manager creates temporary Pod, Service, and Ingress resources to respond to the Let's Encrypt HTTP-01 challenge.

For validation to succeed:

- The requested hostname must resolve publicly to the NGINX Ingress Load Balancer.
- Let's Encrypt must be able to reach the hostname over TCP port `80`.
- The NGINX Ingress Controller must process resources using the `nginx` IngressClass.
- Redirects or firewall rules must not prevent access to the `/.well-known/acme-challenge/` path.

> **Recommendation:** When testing a new configuration, use the Let's Encrypt staging environment first to avoid production rate limits. After validation succeeds, switch to the production endpoint shown in this guide.
