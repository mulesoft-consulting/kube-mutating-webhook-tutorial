# Kubernetes Mutating Webhook for Annotation Injection
Mutating Admission Webhook to generate label on selected Pods.
Pods are selected on the basis of mutatingwebhook.yaml config (on creation and based on namespace annotation)

## Prerequisites
1. Access to a Kubernetes v1.11.3+ cluster with the `admissionregistration.k8s.io/v1beta1` API enabled. Verify that by the following command:

```
kubectl api-versions | grep admissionregistration.k8s.io
```
The result should be:
```
admissionregistration.k8s.io/v1
admissionregistration.k8s.io/v1beta1
```

2. Create a namespace for hosting Webhook and related config (from project root folder):
```
kubectl apply -f deployments/webhook-namespace.yaml
```

3. Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar injector deployment. 
```
scripts/webhook-create-signed-cert.sh \
    --service memulesidecar \
    --secret memulesidecarinject-certs \
    --namespace glin-ap31312mp00875-dev-platform-namespace
```

Verify secret has been created by running:
```
kubectl get secrets/memulesidecarinject-certs -n glin-ap31312mp00875-dev-platform-namespace
```

4. Patch the `mutatingwebhook.yaml` with correct CA Bundle value from Kubernetes cluster. File `mutatingwebhook-ca-bundle.yaml`will be generated.

```
cat deployments/mutatingwebhook.yaml | \
    scripts/webhook-patch-ca-bundle.sh | \
    tee  deployments/mutatingwebhook-ca-bundle.yaml helm/memulesidecar/templates/mutatingwebhook-ca-bundle.yaml
```

5. Annotate your application namespace in order trigger the Mutating Webhook on Pod creation. The required annotation is `enel-sidecar-injector: enabled` (as configured in NamespaceSelector `mutatingwebhook.yaml`).
 ```
kubectl label namespaces 4dddcd4f-d96b-4503-ab65-42ae5a722e0f enel-sidecar-injector=enabled
```

# Build Phase (opt.)
Build to be accomplished in case of own repo usage
1. Go Build (target Linux Alpine) - binary is provided in build/_output folder
```
make build
```

2. Docker Build
Provide target repository
```
make build-image IMAGE_REPO=<docker.io/sbenfa> IMAGE_NAME=<sidecar-injector>
```

3. Push to container registry
```
make push IMAGE_REPO=<docker.io/sbenfa> IMAGE_NAME=<sidecar-injector>
```

## Create Kubernetes resources
You can install the rest of required Kubernetes resources via Helm Chart:
```
helm install memulesidecar ./helm/memulesidecar
```

As an alternative you can create your resources manually, as follows. Please remind to replace `IMAGE_REPO/IMAGE_NAME` with personal repo within `deployments/deployment.yaml`. Please note that file `configmap.yaml` contains the config of the sidecars to be injected.
```
kubectl apply -f deployments/nginxconfigmap.yaml -n <application namespace>
kubectl apply -f deployments/configmap.yaml
kubectl apply -f deployments/deployment.yaml
kubectl apply -f deployments/service.yaml
kubectl apply -f deployments/mutatingwebhook-ca-bundle.yaml
```

And verify which resources have been correctly created by executing:
```
kubectl get deployments -n mutating-webhook -l app=sidecar-injector
kubectl get po -n mutating-webhook -l app=sidecar-injector
kubectl get service/sidecar-injector-svc -n mutating-webhook 
kubectl get mutatingwebhookconfiguration.admissionregistration.k8s.io 
```

## Test
Verify that the target namespace is properly annotated (expected `enel-sidecar-injector: enabled`).
```
kubectl describe ns <application namespace>
```

Create test resource 
```
kubectl apply -f deployments/test.yaml -n <application namespace>
```

Verify that the sidecar container is injected:

```
kubectl get pod -n <application namespace>
NAME                     READY     STATUS        RESTARTS   AGE
test-<xyz>                   2/2       Running       0          1m
```
```
kubectl -n <application namespace> get pod test-<xyz> -o jsonpath="{.spec.containers[*].name}"
test sidecar-nginx
```
And finally clean test deployment:
```
kubectl delete -f deployments/test.yaml -n <application namespace>
```
