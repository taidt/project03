kubectl apply -f ./deployment/env-secret.yaml
kubectl apply -f ./deployment/env-configmap.yaml
kubectl apply -f ./deployment/app-deployment.yaml
kubectl apply -f ./deployment/app-service.yaml
