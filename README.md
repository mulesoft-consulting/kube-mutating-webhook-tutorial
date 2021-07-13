# Kubernetes Mutating Webhook for Annotation Injection
Mutating Admission Webhook to generate inject custom sidecar container based on `sidecar-injector-webhook-configmap` configmap.
Pods are selected on the basis of `mutatingwebhook.yaml` manifest (on creation and based on namespace annotation)

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

3. Mutating Webhook requires TLS in order to be invoked by Kube API Server. Certificates are managed through Kubernetes [cert-manager](https://cert-manager.io/docs/concepts/ca-injector/) 


**Install Cert manager**
```
kubectl create ns cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
```

And verify installation through 
```
kubectl get all -n cert-manager 
```

For cert-manager troubleshooting, refer to [official guide](https://cert-manager.io/docs/faq/troubleshooting/)


**Configure key pairs to allow certificate signing by cert-manager**
Create the key pairs (in the example validity is set to 10 years). Please be sure to create the openssl config upfront, as documented [here](https://github.com/jetstack/cert-manager/issues/279)
```
export COMMON_NAME=memulesidecar.glin-ap31312mp00875-dev-platform-namespace.svc
openssl req -x509 -new -nodes -key ca.key -subj "/CN=${COMMON_NAME}" -days 3650 -extensions v3_ca -out ca.crt -config openssl-with-ca.cnf    
```

And store them in a secret (this will be referenced by cert-manager `Issuer` to generate/renew certificates):
```
kubectl create secret tls ca-key-pair \
   --cert=ca.crt \
   --key=ca.key \
   --namespace=cert-manager
```

For further details about `cert-manager` CRDs and their use, please refer [here](https://docs.cert-manager.io/en/release-0.8/tasks/issuers/setup-ca.html)

4. Annotate your application namespace in order trigger the Mutating Webhook on Pod creation. The required annotation is `enel-sidecar-injector: enabled` (as configured in NamespaceSelector `mutatingwebhook.yaml`).
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

Please remind to replace /helm/memulesidecar/values.yaml with your info (i.e. target repo). 
File `configmap.yaml` contains the config of the sidecars to be injected (to be replaced).
Additional configmap can be added on need and referenced from this,

## Test
Verify resources have been correctly created by executing:
```
kubectl get deployments -n mutating-webhook -l app=sidecar-injector
kubectl get po -n mutating-webhook -l app=sidecar-injector
kubectl get service/sidecar-injector-svc -n mutating-webhook 
kubectl get mutatingwebhookconfiguration.admissionregistration.k8s.io 
```

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
You will notice that injected Pod presents the annotation `enel-sidecar-injector/status=injected`

Finally clean test deployment:
```
kubectl delete -f deployments/test.yaml -n <application namespace>
```
