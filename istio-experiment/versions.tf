terraform {
  required_version = "~>1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.99"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.20"
    }
  }
}
