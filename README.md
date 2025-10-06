# Introduction

These are a couple examples on how to deploy Tailscale using Infrastructure as Code methods, namely:

1. Deploying Tailscale SSH to an existing server using Ansible.
2. Deploying a Tailscale subnet router in a Docker environment via Portainer using Terraform. We will also be deploying an nginx container to the same subnet to demonstrate it can be reached via the subnet router, and add its IP address to a Pi-Hole server's local DNS so we don't have to reference it by IP address.

## Prerequisites

* Ansible and Terraform installed on a system we will run our IaC code from
* A destination Linux server to deploy Tailscale SSH to that can be reached; I am using Ubuntu 24.04.2 LTS
* A destination Docker environment managed by Portainer where we will deploy our Tailscale subnet, a Tailscale subner router, and an nginx container to test reachability
* Optional: a Pi-Hole that we can connect to via API (must have a valid TLS certificate); I am running Pi-Hole in a Docker container that is incidentally reachable via my tailnet
* A Tailscale account and required auth keys
  * Auth keys can be generated under 'Settings | Keys' in the Tailscale Admin Console (or visit 'https://login.tailscale.com/admin/settings/keys')
  * For the purpose of testing, you can make auth keys reusable so that they do not expire each time they are used
  * I like to use 3 different auth keys; one for Ansible, one for Terraform, and one for Portainer/Docker, but you could use a single one if it is reusable

# 1. Deploy Tailscale SSH to an existing server using Ansible

We will leverage Ansible with a specific role to deploy Tailscale SSH to an existing server.

## Requirements

The required role is 'artis3n.tailscale.machine', which can be found here:

`https://github.com/artis3n/ansible-collection-tailscale.git`

This is already defined in the 'requirements.yaml' file, and must be installed by running:

`ansible-galaxy install -r requirements.yaml`

This should create a 'galaxy_roles' folder containing our required role.

## Variables

### Target Host

The group, host and SSH user should be replaced with yours in the 'hosts.ini' file.

In my example:

```
[labo]
nucubuntu.sylvainroy.me ansible_ssh_user=slyyy
```

My group is 'labo' and I have one host (nucubuntu), along with the user I will be using to SSH to the server to run the playbook.


### Vault and Tailscale Authkey

We will create an Ansible vault and vault-password to store our variables, namely the Tailscale authkey.

* Create a '.vault-password' file in the ansible folder with a randomly generated password for our vault.

This vault password file is referenced in the 'ansible.cfg', so it won't need to be entered each time it is used.

* Create the secrets vault:

`ansible-vault create ./vars/secrets.yml`

* And define the tailscale_authey:

tailscale_authkey: your_tailscale_authkey_here

If you need to edit the auth key, or add additional variables to the vault, you can use:

`ansible-vault edit./vars/secrets.yml`

### Enable SSH

Please note that our 'run.yaml' playbook also has the "--ssh" argument defined, which is what indicates that we are not only installing Tailsale, but also enabling SSH.

  vars:
        tailscale_args: "--ssh"

## Deploy

To run the playbook, simply run:

`ansible-playbook run.yaml -kK`

The '-kK' option will prompt us for the connection and privilege escalation password to SSH to the host.

The 'PLAY RECAP' will indicate whether the playbook was succesfully executed or not.

If successful, you should see the server appear under your Machines in the Tailscale Admin Console with an SSH tag.

When you SSH to the host for the first time, you will be prompted to visit a URL to login to Tailscale to approve the connection.



# 2. Deploy Tailscale subnet router in a Docker environment via Portainer

We will leverage Terraform and a Portainer provider to deploy a Tailscale subnet router in a Docker environment via Portainer. 

As an added bonus, we will also be deploying an nginx container to the same subnet to demonstrate it can be reached via the subnet router, and we will leverage a Pi-Hole provider to add its IP address to a Pi-Hole server's local DNS so we don't have to reference it by IP address.

## Variables

Edit the provided 'variables.auto.tfvars.example', removing the '.example', and configuring the following variables:

### Portainer

You should indicate where your Portainer instance can be reached via URL or IP address.

The api_key can be generated under 'My Account' in Portainer as an 'Access token'.

The endpoint ID indicates which endpoint we will be making the changes to in Portainer.

It can be found in the URL of your endpoint's dashboard; for example in my dashboard:

`https://portainer.labo.sylvainroy.me/#!/3/docker/dashboard`

Indicates that my endpoitn ID is '3'.

```
portainer_endpoint = "your_portainer_URL_here"
portainer_api_key = "your_portainer_api_key_here"
portainer_endpoint_id = number_of_your_endpoint_in_portainer
```

### Taiscale

This is where you will enter your Tailscale auth key, and specify which subnet will be used with our subnet router, along with its gateway, and the desired IP address of our subnet router container.

```
TS_AUTHKEY = "your_tailscale_authkey_here"
TS_SUBNET = "192.168.100.0/24"
IP_GATEWAY = "192.168.100.1"
IP_ADDRESS = "192.168.100.2"
```

### nginx

We must provide an IP address in the range of our subnet for our NGINX container, and the desired DNS entry that we will add to our DNS server (the Pi-Hole).

NGINX_IP_ADDRESS = "192.168.100.100"
NGINX_DNS = "desired_dns_entry_here"

### Pi-Hole

We must provide the URL to reach our Pi-Hole server, along with our admin password to authenticate via API.

```
pihole_url = "your_pihole_url_here"
pihole_password = "your_pihole_password_here"
```

## Deploy

First, we must run:

`terraform init`

To initialize the backend and provider plugins.

Then:

`terraform plan`

To generate and validate an execution plan.

And then finally

`terraform apply`

To apply the changes (after entering 'yes' to approve).

If successful, we should see an "Apply complete!" with the number of additions/changes made by Terraform.

We should be able to observe the following:
* 2 new stacks in Portainer, and our 2 new containers
* The 'tailscale-subnet-router' should appear under Machines in the Tailscale Admin Console
* A new local DNS record for our nginx container in our Pi-Hole admin console 
* We should be able to ping the nginx container via the subnet router by its IP or DNS record

# Ressources

## Tailscale

**Tailscale SSH**

https://tailscale.com/kb/1193/tailscale-ssh

**Automate your Tailscale cloud deployments with Terraform | Infrastructure as Code Series Part 2**

https://www.youtube.com/watch?v=PEoMmZOj6Cg&list=PLbKN2w7aG8EIbpIcZ2iGGsFTIZ-zMqLOn&index=4

## Ansible

**ansible-collection-tailscale**

https://github.com/artis3n/ansible-collection-tailscale

## Terraform

**Portainer Provider**

https://registry.terraform.io/providers/portainer/portainer/latest/docs

**Pi-hole Provider**

https://registry.terraform.io/providers/ryanwholey/pihole/latest/docs
