terraform {
  required_version = ">= 0.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.53"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.53"
    }
    template = {
      source = "hashicorp/template"
    }
    namedotcom = {
      source = "registry.namedotcom.local/namedotcom/namedotcom"
    }
  }
}