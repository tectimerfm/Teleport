# AI Use Disclosure

AI tools were used during the preparation of this technical challenge.

The following files were created or modified with assistance from ChatGPT:

## `control-plane-user-data.sh`

**Degree of AI assistance:** High

ChatGPT was used to generate the EC2 User Data script for the Kubernetes control-plane node. The assistance included installation and configuration of containerd, kubelet, kubeadm, kubectl, kernel networking settings, Kubernetes repository configuration, cluster initialization, Flannel deployment, and generation of the worker join command.

The script was created based on the technical requirements provided for the challenge and should be reviewed and tested before use.

## `worker-user-data.sh`

**Degree of AI assistance:** High

ChatGPT was used to generate the EC2 User Data script for the Kubernetes worker nodes. The assistance included installation and configuration of containerd, kubelet, kubeadm, kubectl, kernel networking settings, Kubernetes repository configuration, and the logic required to wait for the Kubernetes API server and join the cluster.

The same script is intended to be used for both worker nodes, with the control-plane private IP configured before deployment.

## `nginx.yaml`

**Degree of AI assistance:** High

ChatGPT was used to generate the Kubernetes manifest based on the requirements provided in the challenge. The manifest defines an Nginx Deployment with two replicas using the `nginx:alpine` image and a ClusterIP Service exposing port 80.

The requested namespace, labels, selectors, replica count, image, container name, and ports were included according to the supplied requirements.

## `AI_DISCLOSURE.md`

**Degree of AI assistance:** High

ChatGPT was used to draft and format this disclosure document so that all files created or modified with AI assistance are explicitly documented.

## Summary

AI assistance was primarily used to generate and structure configuration files and shell scripts from the requirements provided in the challenge. The final files should be reviewed and validated by the candidate before submission.
