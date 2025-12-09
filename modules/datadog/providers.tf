terraform {
  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = "~> 3.23"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}
