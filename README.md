# Test task deploy app-go with Let's Encrypt certificates

## Requirements
* VPC on cloud provider (aws,gce...etc)
* Docker installed https://docs.docker.com/engine/install/debian/
* Kind installed   https://kind.sigs.k8s.io/docs/user/quick-start/
* Terraform install (optional) https://developer.hashicorp.com/terraform/downloads
* Terraform YC cfgs https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs                                

VPC and "kind" cluster can be deployed manualy but it is not a good way. Me presonaly prefer to use IAC tool Trerraform, you cat find it in repo.
# Terraform YC (yandex_cloud)
Create accoutn first if you are haven't got one yet. 
```
cd terraform/
```
first make necessery changes in configuration only if you are use YC and define you personal variables

```
mv terraform.tfvars.example terraform.tfvars

token_val = "your yc token"
cloud_id_val = "yc_cloud_id"
folder_id_val = "yc_folder_id"
zone_val = "yc_cloud_zone"  
```
```
terraform init
terraform plan
terraform apply
```
# Install
#### clone repo 
```
git clone https://github.com/Abnormalist/k8s-apps.git 
cd k8s-apps/
```

Get your external ip

```
curl ifconfig.co

158.160.40.159
```
### Setup DNS
I can log into my DNS provider and point my DNS A record to my IP.
Also setup my router to allow 80 and 443 to come to my PC

If you are running in the cloud, your Ingress controller and Cloud provider will give you a public IP and you can point your DNS to that accordingly.
or use 
 <https://my.freenom.com/>

### deploy metallb

```
kubectl apply -f metallb/metallb-native-v0.13.7.yaml
kubectl get all -n metallb-system
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-84d6d4db45-s9sx5   1/1     Running   0          121m
pod/speaker-q9l9c                 1/1     Running   0          121m

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webhook-service   ClusterIP   10.96.148.151   <none>        443/TCP   121m

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/speaker   1         1         1       1            1           kubernetes.io/os=linux   121m

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           121m

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-84d6d4db45   1         1         1       121m

```
Replace ip range with your external ip: 158.160.40.159 in metallb/ipaddress-pool.yaml spec.addreses
```
vim metallb/ipaddress-pool.yaml

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 158.160.40.159-158.160.40.159
```

create ipaddress-pool.yaml and l2advertisement.yaml
```
kubectl apply -f metallb/ipaddress-pool.yaml
kubectl apply -f metallb/l2advertisement.yaml

```
###  Ingress Controller
```
kubectl apply -f ingress/ingress-nginx-v1.4.0.yaml
```
check if ingress-nginx got the external ip
```
kubectl get svc -n ingress-nginx
default          kubernetes                           ClusterIP      10.96.0.1       <none>           443/TCP                      143m
ingress-nginx    ingress-nginx-controller             LoadBalancer   10.96.188.105   158.160.40.159   80:32087/TCP,443:30912/TCP   20s
ingress-nginx    ingress-nginx-controller-admission   ClusterIP      10.96.202.145   <none>           443/TCP                      20s

Set port forward, it necessery if you use kind cluster as i do
I prefere to use terminal multiplexer tmux for port-forward in background so lets create new session
```
```
tmux new-session -s pf

```
then devide terminal ctrl + b +%  and type command below

```
kubectl -n ingress-nginx --address 0.0.0.0 port-forward svc/ingress-nginx-controller 80
kubectl -n ingress-nginx --address 0.0.0.0 port-forward svc/ingress-nginx-controller 443
```
```
ctrl + b +d  

```
### deploy cert-manager
```
kubectl apply -f cert-manager/cert-manager-v1.10.yaml
kubectl -n cert-manager get all
NAME                                          READY   STATUS    RESTARTS   AGE
pod/cert-manager-6dc4964c9-v9v4n              1/1     Running   0          129m
pod/cert-manager-cainjector-69d4647c6-9jr8m   1/1     Running   0          129m
pod/cert-manager-webhook-75f77865c8-dzjt2     1/1     Running   0          129m

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/cert-manager           ClusterIP   10.96.86.111    <none>        9402/TCP   129m
service/cert-manager-webhook   ClusterIP   10.96.225.146   <none>        443/TCP    129m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cert-manager              1/1     1            1           129m
deployment.apps/cert-manager-cainjector   1/1     1            1           129m
deployment.apps/cert-manager-webhook      1/1     1            1           129m

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/cert-manager-6dc4964c9              1         1         1       129m
replicaset.apps/cert-manager-cainjector-69d4647c6   1         1         1       129m
replicaset.apps/cert-manager-webhook-75f77865c8     1         1         1       129m

```
### Create Let's Encrypt Issuer for our cluster
Replace you e-mail in cert-issuer-nginx-ingress.yaml

```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cluster-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: asgrimm@gmail.com
    privateKeySecretRef:
      name: letsencrypt-cluster-issuer-key
    solvers:
    - http01:
       ingress:
         class: nginx
                  
```

```
kubectl apply -f cert-manager/cert-issuer-nginx-ingress.yaml
```
### Check the issuer
```
kubectl describe clusterissuer letsencrypt-cluster-issuer

```
### Deploy app-go that uses SSL

```
kubectl apply -f apps/app-go.yaml
```
Deploy ingress-nginx rule
```
kubectl apply -f apps/app-go-ingress.yaml
```
### Issue Certificate
Change domain name in the certificate.yaml

```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-go
  namespace: default
spec:
  dnsNames:
    - devilyn.ml
  secretName: letsencrypt
  issuerRef:
    name: letsencrypt-cluster-issuer
    kind: ClusterIssuer
```
```
kubectl apply -f certificate.yaml
```
### check the cert has been issued 
```
kubectl describe certificate app-go
```
### TLS created as a secret
```
kubectl get secrets
AME                TYPE                DATA   AGE
letsencrypt         kubernetes.io/tls   2      72m
letsencrypt-hjk8f   Opaque              1      85m
```

Check that you have a secure connection type your terminal and then a browser.

```
curl -v "https://devilyn.ml/janbo/" 
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200 
< date: Wed, 23 Nov 2022 15:39:34 GMT
< content-type: text/plain; charset=utf-8
< content-length: 25
< strict-transport-security: max-age=15724800; includeSubDomains
< 
* Connection #0 to host devilyn.ml left intact
Hello janbo from @Fredrik

```

Check your browser, type https://devilyn.ml/janbo

if all configured prorerly,resonese will be

Hello janbo from @Fredrik








