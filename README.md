# KubeCTL

**KubeCTL** is a Debian-based Docker image from [Cloudresty](https://cloudresty.com) that contains the [Kubernetes](https://kubernetes.io) command line tool [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/). This image is intended to be used for interacting with Kubernetes clusters being from a local or remote docker host, or from within a Kubernetes cluster itself.

&nbsp;

## Docker Usage

Below are some examples of how to use KubeCTL as a Docker container. In this example, the container will be started with a shell prompt and the credentials for a Kubernetes cluster will have to be provided manually by passing them to `~/.kube/config` within the container.

&nbsp;

### Simple Docker Usage

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --name kubectl \
    --hostname kubectl \
    cloudresty/kubectl:latest zsh
```

&nbsp;

KubeCTL as a Docker container can also be used to interact with a Kubernetes cluster from a remote or local docker host. In this example, the container will be started with a shell prompt and the credentials for a Kubernetes cluster will be provided by mounting the `~/.kube` directory from the remote or local docker host to the container.

&nbsp;

### Docker Usage with mounted ~/.kube directory

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --name kubectl \
    --hostname kubectl \
    --volume ~/.kube:/root/.kube \
    cloudresty/kubectl:latest zsh
```

&nbsp;

If you have multiple Kubernetes clusters, make sure you have the correct context selected before running any commands.

&nbsp;

## Kubernetes Usage

KubeCTL can be used as a shell pod within a Kubernetes cluster. In this example, the pod will be started with a shell prompt and the access to the Kubernetes cluster will be provided by a service account. In this example, the service account will be created in the `cloudresty-system` namespace and will be given cluster-admin privileges. The service account will be named `ksa-kubectl`.

For security reasons, it is recommended to create a new namespace for the service account and to give the service account only the privileges it needs to perform its intended tasks.

This approach is useful for when you need to run KubeCTL commands from within a Kubernetes cluster itself. For example, you may want to run KubeCTL scheduled commands from within a Kubernetes cluster to perform tasks such as creating new namespaces, creating new service accounts, creating new roles, creating new role bindings, CronJobs, HPAs, deployment roll-outs, etc. that are non-standard and cannot be performed using the standard Kubernetes resources.

&nbsp;

### Kubernetes Pod Usage with Service Account

```yaml
#
# KubeCTL Namespace
#

apiVersion: v1
kind: Namespace
metadata:
  name: cloudresty-system

---

#
# KubeCTL Service Account
#

apiVersion: v1
kind: ServiceAccount
metadata:
  name: ksa-kubectl
  namespace: cloudresty-system

---

#
# KubeCTL Cluster Role Binding
#

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ksa-kubectl
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: ksa-kubectl
    namespace: cloudresty-system
```

```bash
kubectl run \
    --namespace cloudresty-system \
        kubectl \
        --stdin \
        --tty \
        --rm \
        --restart Never \
        --image cloudresty/kubectl:latest \
        --image-pull-policy Always \
        --override-type strategic \
        --overrides '{ "apiVersion": "v1", "spec": {"serviceAccountName":"ksa-kubectl" }}' \
        --command -- zsh
```

&nbsp;

### Kubernetes CronJob Usage with Service Account

```yaml
#
# KubeCTL Namespace
#

apiVersion: v1
kind: Namespace
metadata:
  name: cloudresty-system

---

#
# KubeCTL Service Account
#

apiVersion: v1
kind: ServiceAccount
metadata:
  name: ksa-kubectl
  namespace: cloudresty-system

---

#
# KubeCTL Cluster Role Binding
#

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ksa-kubectl
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: ksa-kubectl
    namespace: cloudresty-system

---

#
# KubeCTL CronJob
#

apiVersion: batch/v1
kind: CronJob
metadata:
  name: kubectl
  namespace: cloudresty-system
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ksa-kubectl
          containers:
            - name: kubectl
              image: cloudresty/kubectl:latest
              imagePullPolicy: Always
              command:
                - zsh
              args:
                - -c
                - |
                  kubectl get pods --all-namespaces
          restartPolicy: OnFailure
```

&nbsp;

---
Copyright &copy; [Cloudresty](https://cloudresty.com)
