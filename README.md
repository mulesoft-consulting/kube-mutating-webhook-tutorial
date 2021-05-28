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

2. Create a namaspace called `mutating-webhook`
```
kubectl create ns mutating-webhook
```

3. Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar injector deployment. 

From `deploy` folder:
```
./webhook-create-signed-cert.sh \
    --service sidecar-injector-webhook-svc \
    --secret sidecar-injector-webhook-certs \
    --namespace mutating-webhook
```

4. Patch the `mutatingwebhook.yaml` with correct CA Bundle value from Kubernetes cluster. File `mutatingwebhook-ca-bundle.yaml`will be generated.

```
cat mutatingwebhook.yaml | \
    ./webhook-patch-ca-bundle.sh > \
    mutatingwebhook-ca-bundle.yaml
```

## Build
Change `IMAGE_REPO` and `IMAGE_NAME` parameters in `Makefile` (including target image repo)

1. Build binary

```
make build
```

2. Build docker image
   
```
make build-image
```

3. push docker image

```
make push-image
```

## Deploy

Please note that file `configmap.yaml` contains the config of the sidecars to be injected.
From `deploy`folder launch:

```
kubectl apply -f nginxconfigmap.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f mutatingwebhook-ca-bundle.yaml
```

## Test
Annotate namespace (as configured in namespaceSelector in mutatingwebhook.yaml)
 ```
kubectl label namespaces <application namespace> enel-sidecar-injector=enabled
```

Create test resource 
```
kubectl apply -f test.yaml -n <application namespace>
```

And finally verify sidecar container is injected:

```
kubectl get pod -n <application namespace>
NAME                     READY     STATUS        RESTARTS   AGE
test-<xyz>                   2/2       Running       0          1m
kubectl -n <application namespace> get pod test-<xyz> -o jsonpath="{.spec.containers[*].name}"
test sidecar-nginx
```

