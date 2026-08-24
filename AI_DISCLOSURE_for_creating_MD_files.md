# AI Use Disclosure

I used ChatGPT as an assistant while completing this challenge. AI assistance was primarily used to draft scripts and Kubernetes manifests, improve documentation structure, translate content from Portuguese into English, check command syntax, and identify technical considerations.

All architectural decisions, infrastructure configuration, deployment steps, troubleshooting, and validation were performed and reviewed by me. I manually executed the commands in my AWS and Kubernetes environment and verified the final results.

## Files Created or Modified with AI Assistance

| File | Degree of Assistance | Description |
| --- | --- | --- |
| `ec2_kubernetes_install.sh` | High | ChatGPT helped draft and organize the EC2 User Data script used to install Kubernetes, containerd, kubeadm, kubelet, and kubectl. I reviewed the script, selected the versions and configuration, and tested it on the EC2 instances. |
| `1-kubernetes-cluster-setup.md` | High | ChatGPT helped reorganize and translate the kubeadm and Flannel installation procedure into English. I supplied the commands, cluster configuration, networking choices, and results from my environment. |
| `2-RBAC-permissions-client-certificate-nginx-user.md` | High | ChatGPT helped structure the RBAC configuration, client certificate procedure, kubeconfig creation steps, and validation commands. I defined the required access model, reviewed the permissions, and tested the configuration against the cluster. |
| `3-cert-manager-letsencrypt-clusterissuer.md` | High | ChatGPT helped reorganize and translate the cert-manager and Let's Encrypt ClusterIssuer procedure. I supplied the selected ingress class, DNS configuration, certificate requirements, and tested the final configuration. |
| `nginx.yaml` | Medium | ChatGPT helped format the Kubernetes Deployment and Service manifests based on my requirements. I specified the namespace, image, replica count, labels, ports, and Service type, and then deployed and validated the resources. |
| `kubernetes-project.md` | High | ChatGPT helped translate, reorganize, and improve the overall project documentation. The infrastructure details, architecture decisions, implementation steps, troubleshooting findings, limitations, and final recommendations were based on my own environment and work. |
| `kubernetes-architecture.png` | High | The architecture diagram was generated with AI based on the AWS and Kubernetes design that I provided. I reviewed the diagram and requested corrections to accurately represent IONOS DNS, the AWS NLB, worker NodePorts, ingress-nginx, cert-manager, Let's Encrypt, and the NGINX workload. |
| `AI_DISCLOSURE.md` | High | ChatGPT helped draft and format this disclosure based on my description of how AI was used throughout the project. I reviewed the final disclosure for accuracy and completeness. |

## Nature of the AI Assistance

AI was used for:

- Drafting initial Bash, YAML, and Markdown content.
- Translating technical documentation from Portuguese into English.
- Improving grammar, readability, and document organization.
- Checking Kubernetes command and manifest syntax.
- Suggesting validation and troubleshooting commands.
- Explaining security considerations and operational limitations.
- Generating the architecture diagram from my specified design.
- Comparing the manually managed kubeadm approach with a possible Amazon EKS implementation.

AI was not used to fabricate test results or claim that commands had been executed successfully without verification. I manually created the AWS infrastructure, ran the Kubernetes commands, tested the RBAC permissions, validated the NGINX deployment, configured public access, and confirmed the HTTPS endpoint.

I reviewed all AI-assisted content and take responsibility for the accuracy and final implementation submitted with this challenge.
