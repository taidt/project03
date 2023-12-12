# project03 22

step 2: aws eks --region us-east-1 update-kubeconfig --name project03-eks  
step 3: helm repo add tutai92-pr3 https://charts.bitnami.com/bitnami 
        helm install --set primary.persistence.enabled=false project03 tutai92-pr3/postgresql


** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    project03-postgresql.default.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace default project03-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)     

To connect to your database run the following command:

    kubectl run project03-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:16.1.0-debian-11-r15 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host project03-postgresql -U postgres -d postgres -p 5432

    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/project03-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432


    kubectl port-forward --namespace default svc/<SERVICE_NAME>-postgresql 5432:5432 &

    kubectl port-forward --namespace default svc/project03-postgresql 5432:5432 & PGPASSWORD="a1lNekdPMnNTUA==" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/1_create_tables.sql

    kubectl port-forward --namespace default svc/$TYPE_NAME $LOCAL_PORT:$REMOTE_PORT > /dev/null 2>&1

    kubectl port-forward --namespace default svc/project03-postgresql 5432:5432 > /dev/null 2>&1


    kubectl apply -f ./eks_deployments/env-secret.yaml

    kubectl apply -f ./eks_deployments/env-configmap.yaml

    kubectl apply -f ./eks_deployments/app-deployment.yaml

    kubectl apply -f ./eks_deployments/app-service.yaml

    kubectl expose deployment app-coworking --type=LoadBalancer --name=publicbackend

