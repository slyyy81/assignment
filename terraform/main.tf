terraform {
  required_providers {
    portainer = {
      source = "portainer/portainer"
      version = "1.13.0"
    }
    pihole = {
      source = "ryanwholey/pihole"
      version = "2.0.0-beta.1"
    }
  }
}

variable "portainer_endpoint" {}
variable "portainer_api_key" {}
variable "portainer_endpoint_id" {}
variable "TS_AUTHKEY" {}
variable "TS_SUBNET" {}
variable "IP_GATEWAY" {}
variable "IP_ADDRESS" {}
variable "NGINX_IP_ADDRESS" {}
variable "NGINX_DNS" {}
variable "pihole_password" {}
variable "pihole_url" {}


provider "portainer" {
  endpoint = var.portainer_endpoint

  # Option 1: API key authentication
  api_key  = var.portainer_api_key

  skip_ssl_verify  = true # optional (default value is `false`)
}

provider "pihole" {
  url      = var.pihole_url       # PIHOLE_URL
  password = var.pihole_password  # PIHOLE_PASSWORD
}


resource "portainer_stack" "tailscale-subnet-router" {
  name              = "tailscale-subnet-router"
  deployment_type   = "standalone"
  method            = "file"
  endpoint_id       = var.portainer_endpoint_id
  stack_file_path   = "./tailnet-docker-compose.yml"

  env {
    name = "IP_ADDRESS"
    value = var.IP_ADDRESS
  }
  env {
    name  = "TS_AUTHKEY"
    value = var.TS_AUTHKEY
  }
  env {
    name = "TS_SUBNET"
    value = var.TS_SUBNET
  }
  env {
    name = "IP_GATEWAY"
    value = var.IP_GATEWAY
  }
}

resource "portainer_stack" "nginx-tailscale" {
  name              = "nginx-tailscale"
  deployment_type   = "standalone"
  method            = "file"
  endpoint_id       = 3
  stack_file_path   = "./nginx-docker-compose.yml"

  env {
    name = "IP_ADDRESS"
    value = var.NGINX_IP_ADDRESS
  }
}

resource "pihole_dns_record" "nginx" {
  domain = "nginx.labo.sylvainroy.me"
  ip     = var.NGINX_IP_ADDRESS
}