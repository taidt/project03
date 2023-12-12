variable "prj03_ecr_name" {
  type    = string
  default = "project03-ecr"
}

variable "prj03_eks_cluster_role" {
  type    = string
  default = "project03-eks-role"
}

variable "prj03_eks_cluster_security_group" {
  type    = string
  default = "project03-eks-cluster-security-group"
}

variable "prj03_eks_cluster_name" {
  type    = string
  default = "project03-eks"
}

variable "prj03_eks_worker_node_security_group" {
  type    = string
  default = "project03-eks-work-node-security-group"
}

variable "prj03_eks_worker_node_role" {
  type    = string
  default = "project03-eks-worker-node-role"
}

variable "prj03_eks_worker_node_name" {
  type    = string
  default = "project03-eks-worker-node"
}

variable "prj03_eks_worker_node" {
  type    = string
  default = "project03-eks-worker-node"
}

variable "prj03_git_repo_url" {
  type    = string
  default = "https://github.com/taidt/project03-operationalizing-a-coworking-space-microservice"
}

variable "prj03_github_access_token" {
  type    = string
  default = "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"
}

variable "prj03_codebuild-ecr-role" {
  type    = string
  default = "project03-cb-ecr-role"
}
