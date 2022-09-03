# Terraform salamandre

This repository contains the infrastructure as code with Terraform for `salamandre` cluster.

## Commands

### For Vagrant

```sh
cd terraform && terraform apply -var-file="terraform.vm.tfvars"
```

### For production

```sh
cd terraform && terraform apply -var-file="terraform.tfvars"
```
