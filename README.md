# Terraform and Ansible Integration

## Overview

This project demonstrates a basic integration of Terraform with Ansible to provision and configure a Virtual Machine in Azure. The step-by-step guide below includes prerequisites setup, infrastructure provisioning, VM configuration, connection testing, and teardown. This guide is an extension of the Tutorial discussed in the article: "[Terraform and Ansible on Azure: Building Robust Infrastructure on Cloud Platforms](https://medium.com/itnext/terraform-and-ansible-on-azure-9bb740746e3a)."

### Prerequisites

- Ensure you are in a Linux environment. If you're on Windows, use [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install).
- Install [Terraform](https://www.terraform.io/downloads.html) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

### Workflow

1. Provision infrastructure using Terraform:
    - Resource Group
    - Virtual Network and Subnet
    - Public IP and Network Interface
    - Virtual Machine with SSH keys
    - Generate `inventory.yml` file for Ansible
2. Configure the Virtual Machine with Ansible:
    - Install Nginx
    - Create a `last-deployment.txt` file containing deployment timestamp
3. Test VM and Nginx connection:
    - Use `curl` to access the Nginx default page
    - Check the `last-deployment.txt` contents
4. Teardown:
    - Destroy provisioned infrastructure
    - Cleanup local files

## Directory Structure

```bash
.
├── README.md
├── ansible
│   ├── group_vars
│   │   └── all.yml
│   ├── inventory.yml
│   ├── playbooks
│   │   └── main.yml
│   └── roles
│       ├── deployment_timestamp
│       │   └── tasks
│       │       └── main.yml
│       └── nginx
│           └── tasks
│               └── main.yml
└── terraform
    ├── main.tf
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    ├── terraform.tfvars
    ├── variables.tf
    └── versions.tf
```


## Prepare SSH keys and set Environment Variables

```bash
# Create ssh keys in ~/.ssh folder and set proper access rights
mkdir -p ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/adminuser -N "" -q
chmod 600 ~/.ssh/adminuser


# Export Azure subscription ID variable
export AZURE_SUBSCRIPTION="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Export administrator username variable for VM
export ADMINUSER=adminuser

# Export path to the SSH public key
export SSH_PUBLIC_KEY=/home/user/.ssh/adminuser.pub

# Export path to the SSH private key
export SSH_PRIVATE_KEY=/home/user/.ssh/adminuser
```



## Provision Virtual Machine (Terraform)

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Create a Terraform plan with variable values provided
terraform plan \
    -var="ssh_public_key_path=$SSH_PUBLIC_KEY" \
    -var="subscription=$AZURE_SUBSCRIPTION" \
    -var="vm_admin_username=$ADMINUSER"

# Apply the Terraform plan to create resources with auto-approval
terraform apply -auto-approve \
    -var="ssh_public_key_path=$SSH_PUBLIC_KEY" \
    -var="subscription=$AZURE_SUBSCRIPTION" \
    -var="vm_admin_username=$ADMINUSER"
```


# Configure Virtual Machine (Ansible)

```bash

# Move to the Ansible directory
cd ../ansible

# Copy the inventory file created by Terraform
cp ../terraform/inventory.yml .

# Execute the Ansible playbook with the specified inventory and SSH private key
ansible-playbook -i inventory.yml playbooks/main.yml --extra-vars "ansible_ssh_private_key_file=$SSH_PRIVATE_KEY"
```

## Check

```bash
# Retrieve the IP address from the inventory file
export VM_IP_ADDRESS=$(awk '/hosts/ { getline; print $1 }' inventory.yml | awk -F\" '{print $2}')
echo $VM_IP_ADDRESS

# Test the Nginx default page
curl $VM_IP_ADDRESS

# Log in to the VM and verify the last-deployment.txt file
ssh -i $SSH_PRIVATE_KEY $ADMINUSER@$VM_IP_ADDRESS
ls -lisa
cat last-deployment.txt
```

## Teardown

```bash
# Switch to the Terraform directory for teardown
cd ../terraform

# Destroy all Terraform-managed infrastructure without prompt
terraform destroy -auto-approve \
    -var="ssh_public_key_path=$SSH_PUBLIC_KEY" \
    -var="subscription=$AZURE_SUBSCRIPTION" \
    -var="vm_admin_username=$ADMINUSER"

# Remove the inventory files
cd ..
rm ansible/inventory.yml
rm terraform/inventory.yml
```

# Conclusion

Congratulations on completing this step-by-step journey of integrating Terraform with Ansible to build and manage infrastructure on Azure. If you've followed along, you've now seen how these powerful tools work in tandem to provision and fine-tune a virtual environment capable of hosting a web service.

For the complete guide and deeper insights, refer to the article "[Terraform and Ansible on Azure: Building Robust Infrastructure on Cloud Platforms](https://medium.com/itnext/terraform-and-ansible-on-azure-9bb740746e3a)."

Feel free to explore, fork, and adopt these patterns in your projects.