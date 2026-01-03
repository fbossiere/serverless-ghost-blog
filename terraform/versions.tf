terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
      version = ">= 2.65.1"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}
