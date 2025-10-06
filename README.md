# Table of Contents
 - Introduction
   - Prerequisites
 - Deploy Tailscale SSH to an existing server using Ansible
   - Requirements
   -  Variables
      - Target host
      - Vault and Tailscale Auth Key
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
2. Deploying a Tailscale subnet router in a Docker environment via Portainer using Terraform. In addition, an NGINX container will be deployed to the same subnet to demonstrate that it can be reached via the subnet router, and its IP address will be added to a Pi-hole server's local DNS so it does not have to referenced by IP address.

## Prerequisites

* Ansible and Terraform installed on a system from which the IaC code will be run
* A destination Linux server on which to deploy Tailscale SSH
* A destination Docker environment managed by Portainer on which to deploy the Tailscale subnet, a Tailscale subnet router, and an NGINX container to test reachability
* A Tailscale account and required auth keys
  * Auth keys can be generated under 'Settings | Keys' in the Tailscale Admin Console (or visit 'https://login.tailscale.com/admin/settings/keys')
  * For the purpose of testing, auth keys can be made reusable so that they do not expire after each use
  * I like to use 3 different auth keys; one for Ansible, one for Terraform, and one for Portainer/Docker, but a single reusable one could be used instead
* Optional: a Pi-hole that can be connected to via API (must have a valid TLS certificate)

# 1. Deploy Tailscale SSH to an existing server using Ansible

Leverage Ansible with a specific role to deploy Tailscale SSH to an existing server.

## Requirements

The required role is 'artis3n.tailscale.machine', which can be found here:

`https://github.com/artis3n/ansible-collection-tailscale.git`

The role is already defined in the 'requirements.yaml' file, which must now be installed.

Run the following command to install the requirements:

`ansible-galaxy install -r requirements.yaml`

This will create a 'galaxy_roles' folder containing the required role.

## Variables

### Target Host

Replace the group, host and SSH user in the 'hosts.ini' file.

In my version of the 'hosts.ini' file, the group is 'labo' and I have one host (nucubuntu), along with the user that will be used to SSH to the server when running the playbook.

```
[labo]
nucubuntu.sylvainroy.me ansible_ssh_user=slyyy
```

### Vault and Tailscale Auth Key

Next, create an Ansible vault and vault-password to store the variables, namely the Tailscale auth key.

#### Vault Password

Create a '.vault-password' file in the 'ansible' folder with a randomly generated password for the vault.

This vault password file is referenced in 'ansible.cfg', so it will not need to be re-entered each time it is used.

#### Secrets Vault

Create the secrets vault:

`ansible-vault create ./vars/secrets.yml`

And define the tailscale_authkey:

`tailscale_authkey: your_tailscale_authkey_here`

If you need to edit the auth key, or add additional variables to the vault, you can use:

`ansible-vault edit./vars/secrets.yml`

### Enable SSH

Please note that the 'run.yaml' playbook also has the "--ssh" argument defined, which is what indicates that not only should Tailscale be installed (via the assigned role), but that SSH should also be enabled.

```
  vars:
        tailscale_args: "--ssh"
```

## Deploy

Run the following command to execute the playbook:

`ansible-playbook run.yaml -kK`

The '-kK' options will prompt you for the connection and privilege escalation password to SSH to the host, and may be omitted if they are not required.

The 'PLAY RECAP' will indicate whether the playbook was successfully executed or not.

If successful, the server will appear under Machines in the Tailscale Admin Console with an SSH tag.

Please note that when the first connection via Tailnet SSH is made, a prompt will ask the user to log in to their Tailscale account and approve the connection.

# 2. Deploy a Tailscale subnet router in a Docker environment via Portainer using Terraform

Leverage Terraform with a Portainer provider to deploy a Tailscale subnet router container in a Docker environment via Portainer. 

Optional: Deploy an NGINX container to the same subnet to demonstrate that it can be reached via the subnet router, and use a Terraform Pi-hole provider to add its IP address to a Pi-hole server's local DNS (so it does not have to be referenced by IP address).

## Variables

Edit the provided 'variables.auto.tfvars.example', removing the '.example', and configure the following variables:

### Portainer

#### portainer_endpoint

Indicates where your Portainer instance can be reached via URL or IP address.

#### portainer_api_key

The api_key can be generated under 'My Account' in Portainer as an 'Access token'.

#### portainer_endpoint_id

The endpoint ID indicates which endpoint you will be making the changes to in Portainer.

It can be found in the URL of the Portainer endpoint's dashboard.

For example, in my dashboard, the URL is:

`https://portainer.labo.sylvainroy.me/#!/3/docker/dashboard`

This indicates that my endpoint ID is '3'.

```
portainer_endpoint = "your_portainer_URL_here"
portainer_api_key = "your_portainer_api_key_here"
portainer_endpoint_id = number_of_your_endpoint_in_portainer
```

### Tailscale

Enter your Tailscale auth key, and specify which subnet will be used with the subnet router, along with its gateway, and the desired IP address of the subnet router container.

```
TS_AUTHKEY = "your_tailscale_authkey_here"
TS_SUBNET = "192.168.100.0/24"
IP_GATEWAY = "192.168.100.1"
IP_ADDRESS = "192.168.100.2"
```

### NGINX

Provide an IP address in the range of our subnet for the NGINX container, and the desired DNS entry that we will added to the DNS server (Pi-hole).

```
NGINX_IP_ADDRESS = "192.168.100.100"
NGINX_DNS = "desired_dns_entry_here"
```

### Pi-hole

Provide the URL to reach the Pi-hole server, along with the admin password to authenticate via API.

```
pihole_url = "your_pihole_url_here"
pihole_password = "your_pihole_password_here"
```

## Deploy

### main.tf

'main.tf' defines the providers (Portainer and Pi-hole), and creates the ressources: one Portainer stack for the subnet router container, one Portainer stack for the NGINX container, and a DNS entry in Pi-hole.

### Run

First, run:

`terraform init`

to initialize the backend and provider plugins.

Then run:

`terraform plan`

to generate and validate an execution plan.

And then finally run:

`terraform apply`

to apply the changes (after entering 'yes' to approve).

If successful, the resulting output should read "Apply complete!" alongside the number of additions and/or changes made by Terraform.

You should be able to observe the following:
* 2 new stacks in Portainer, and your 2 new containers
* The 'tailscale-subnet-router' should appear under Machines in the Tailscale Admin Console
* A new local DNS record for your NGINX container in your Pi-hole admin console 
* You should be able to ping the NGINX container via the subnet router by its IP or DNS record

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

