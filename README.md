## Getting Started
Start by cloning the starter repository for the project.

## Remote Resource Requirements
This project utilizes Amazon Web Services (AWS). You'll find instructions for using a temporary AWS account on the next page. The AWS resources you'll need to use for the project include:

AWS CLI
AWS CodeBuild - build Docker images remotely
AWS ECR - host Docker images
Kubernetes Environment with AWS EKS - run applications in k8s
AWS CloudWatch - monitor activity and logs in EKS
Project Instructions
Dependencies
AWS Account
AWS CLI
Terraform
Helm Chart
PostgresSQL
VSCode
Clone the project

Clone Project Code

git clone https://github.com/taidt/project03-operationalizing-a-coworking-space-microservice

## How to run
- Create AWS resource with terraform

- Config Kubect with EKS Cluster Name

- Set up PostgreSQL with Helm Chart

- Seed data using kubectl port-forward and psql

- Create AWS CodePipeline to build and push image to AWS ECR

- Create a service and deployment yaml files to deploy web api

- Apply configmap, secret, service and deployment yaml files

- Create an external load balancer using kubectl expose

- Check web api

- Check logs from CloudWatch and kubectl logs pod-name

Run at ./scripts

## Verifying The Application
Generate report for check-ins grouped by dates

curl <BASE_URL>/api/reports/daily_usage
Generate report for check-ins grouped by users

curl <BASE_URL>/api/reports/user_visits

