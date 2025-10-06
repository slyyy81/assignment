# Table of Contents
 - Introduction
   - Prerequisites
 - Deploy Tailscale SSH to an existing server using Ansible
   - Requirements
   -  Variables
      - Target host
      - Vault and Tailscale Authkey
      - Enable SSH
   - Deploy
 - Deploy a Tailscale subnet router in a Docker environment via Portainer using Terraform
   -  Variables
      -  Portainer
      -  Tailscale
      -  NGINX
      -  Pi-hole
   -  Deploy
 -  Resources

# Introduction

This project demonstrates two ways to deploy Tailscale using Infrastructure as Code methods, namely:

1. Deploying Tailscale SSH to an existing server using Ansible.
2. Deploying a Tailscale subnet router in a Docker environment via Portainer using Terraform. We will also be deploying an nginx container to the same subnet to demonstrate that it can be reached via the subnet router, and add its IP address to a Pi-Hole server's local DNS so that it does not have to referenced by IP address.

## Prerequisites

* Ansible and Terraform installed on a system from which our IaC code will be run
* A destination Linux server on which we will deploy Tailscale SSH
* A destination Docker environment managed by Portainer where we will deploy our Tailscale subnet, a Tailscale subner router, and an nginx container to test reachability
* Optional: a Pi-Hole that we can connect to via API (must have a valid TLS certificate); I am running Pi-Hole in a Docker container that is incidentally reachable via my tailnet
* A Tailscale account and required auth keys
  * Auth keys can be generated under 'Settings | Keys' in the Tailscale Admin Console (or visit 'https://login.tailscale.com/admin/settings/keys')
  * For the purpose of testing, auth keys can be made reusable so that they do not expire each time they are used
  * I like to use 3 different auth keys; one for Ansible, one for Terraform, and one for Portainer/Docker, but a single reusable one could also be used

# 1. Deploy Tailscale SSH to an existing server using Ansible

We will leverage Ansible with a specific role to deploy Tailscale SSH to an existing server.

## Requirements

The required role is 'artis3n.tailscale.machine', which can be found here:

`https://github.com/artis3n/ansible-collection-tailscale.git`

This is already defined in the 'requirements.yaml' file, and must be installed.

Run the following command to install the requirements:

`ansible-galaxy install -r requirements.yaml`

This should create a 'galaxy_roles' folder containing our required role.

## Variables

### Target Host

Replace the group, host and SSH user in the 'hosts.ini' file.

In my version of the 'hosts.ini' file, group is 'labo' and I have one host (nucubuntu), along with the user that will be used to SSH to the server when running the playbook.

```
[labo]
nucubuntu.sylvainroy.me ansible_ssh_user=slyyy
```

### Vault and Tailscale Authkey

We will next create an Ansible vault and vault-password to store the variables, namely our Tailscale authkey.

#### Vault Password

Create a '.vault-password' file in the 'ansible' folder with a randomly generated password for our vault.

This vault password file is referenced in the 'ansible.cfg', so it won't need to be entered each time it is used.

#### Secrets Vault

Create the secrets vault:

`ansible-vault create ./vars/secrets.yml`

And define the tailscale_authey:

tailscale_authkey: your_tailscale_authkey_here

If you need to edit the auth key, or add additional variables to the vault, you can use:

`ansible-vault edit./vars/secrets.yml`

### Enable SSH

Please note that our 'run.yaml' playbook also has the "--ssh" argument defined, which is what indicates that we are not only installing Tailsale (via the assigned role), but also enabling SSH.

```
  vars:
        tailscale_args: "--ssh"
```

## Deploy

Run the following command to execute the playbook:

`ansible-playbook run.yaml -kK`

The '-kK' options will prompt us for the connection and privilege escalation password to SSH to the host, and may be omitted if they are not required.

The 'PLAY RECAP' will indicate whether the playbook was succesfully executed or not.

If successful, the server should appear under Machines in the Tailscale Admin Console with an SSH tag.

When first connecting via SSH, a prompt will appear to visit a URL to login to Tailscale, and approve the connection.



# 2. Deploy a Tailscale subnet router in a Docker environment via Portainer using Terraform

We will leverage Terraform, with a Portainer provider, to deploy a Tailscale subnet router container in a Docker environment via Portainer. 

Optionally, we will also deploy an nginx container to the same subnet to demonstrate it can be reached via the subnet router, and we will leverage a Terraform Pi-Hole provider to add its IP address to a Pi-Hole server's local DNS (so we don't have to reference it by IP address).

## Variables

Edit the provided 'variables.auto.tfvars.example', removing the '.example', and configure the following variables:

### Portainer

#### portainer_endpoint

Indicates where your Portainer instance can be reached via URL or IP address.

#### portainer_api_key

The api_key can be generated under 'My Account' in Portainer as an 'Access token'.

#### portainer_endpoint_id

The endpoint ID indicates which endpoint we will be making the changes to in Portainer.

It can be found in the URL of the Portainer endpoint's dashboard.

For example in my dashboard, the URL is:

`https://portainer.labo.sylvainroy.me/#!/3/docker/dashboard`

Which Indicates that my endpoint ID is '3'.

```
portainer_endpoint = "your_portainer_URL_here"
portainer_api_key = "your_portainer_api_key_here"
portainer_endpoint_id = number_of_your_endpoint_in_portainer
```

### Taiscale

Enter your Tailscale auth key, and specify which subnet will be used with the subnet router, along with its gateway, and the desired IP address of the subnet router container.

```
TS_AUTHKEY = "your_tailscale_authkey_here"
TS_SUBNET = "192.168.100.0/24"
IP_GATEWAY = "192.168.100.1"
IP_ADDRESS = "192.168.100.2"
```

### nginx

Provide an IP address in the range of our subnet for the NGINX container, and the desired DNS entry that we will added to the DNS server (Pi-Hole).

```
NGINX_IP_ADDRESS = "192.168.100.100"
NGINX_DNS = "desired_dns_entry_here"
```

### Pi-Hole

Provide the URL to reach the Pi-Hole server, along with the admin password to authenticate via API.

```
pihole_url = "your_pihole_url_here"
pihole_password = "your_pihole_password_here"
```

## Deploy

### main.tf

'main.tf' defines the providers (Portainer and Pi-Hole), and creates the ressources: one portainer stack for the subnet router container, one portainer stack for the nginx container, and a DNS entry in Pi-Hole.

### Run

First, run:

`terraform init`

to initialize the backend and provider plugins.

Then run:

`terraform plan`

to generate and validate an execution plan.

And then finally

`terraform apply`

to apply the changes (after entering 'yes' to approve).

If successful, the resulting output should read "Apply complete!" with the number of additions/changes made by Terraform.

We should be able to observe the following:
* 2 new stacks in Portainer, and our 2 new containers
* The 'tailscale-subnet-router' should appear under Machines in the Tailscale Admin Console
* A new local DNS record for our nginx container in our Pi-Hole admin console 
* We should be able to ping the nginx container via the subnet router by its IP or DNS record

# Resources

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
