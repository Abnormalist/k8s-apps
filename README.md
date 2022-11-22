# Test task app-go
# Requirements
* VPC on cloud provider (aws,gce...etc)
* Docker,kind installed

# Deploy
clone repo https://github.com/Abnormalist/k8s-apps.git; 

```
cd k8s-apps/
```

Get your external ip

```
curl ifconfig.co
158.160.40.159
```
deploy metallb

```
kubectl apply -f metallb/metallb-native-v0.13.7.yaml
kubectl get svc -n metallb-system
```
replace IP range with your external IP in metallb/ipaddress-pool.yaml

create ipaddress-pool.yaml and l2advertisement.yaml
```
kubectl apply -f metallb/ipaddress-pool.yaml
kubectl apply -f metallb/l2advertisement.yaml

```


deploy cert-manager
```
kubectl apply -f cert-manager/cert-manager-v1.10.yaml
```
deploy ingress-nginx
```
kubectl apply -f ingress/ingress-nginx-v1.4.0.yaml

```
* depploy app + service + ingres-rule





