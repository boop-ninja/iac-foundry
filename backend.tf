terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "boop-ninja"

    workspaces {
      prefix = "iac-foundry-"
    }
  }
}