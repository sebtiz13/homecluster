.PHONY: help init install init-upgrade
.SILENT:
.DEFAULT_GOAL= help

TERRRAFORM_DIR := ./terraform
VAGRANT_DIR := ./vagrant

help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

init: ## Init environment of Terraform
	echo "Initializing terraform environment..."
	terraform version
	cd terraform; terraform init

init-upgrade: ## Init/upgrade environment of Terraform
	echo "Initializing terraform environment..."
	terraform version
	cd terraform; terraform init --upgrade

validate: ## Terraform files
	cd terraform; terraform validate

cleanup: ## Cleanup init an testing environment
	rm -rf terraform/.terraform
	make vm-destroy --no-print-directory

cluster: ## All-in-one command for cluster deployment
	make init --no-print-directory
	echo "Provisining cluster..."
	cd terraform; terraform apply -auto-approve && terraform refresh

test-cluster: ## All-in-one command for cluster deployment inside VM
	make init --no-print-directory
	make vm-create --no-print-directory
	echo "Provisining cluster..."
	cd terraform; terraform apply -var-file="vm.tfvars" -auto-approve && terraform refresh

vagrant: ## (Re)create vagrant VM
	make vm-create --no-print-directory
	make vm-destroy --no-print-directory
vm-create: ## Create vagrant VM
	echo "Creating new VM(s)..."
	cd $(VAGRANT_DIR); vagrant up $(VM_NAME)
vm-destroy: ## Destroying vagrant VM
	echo "Destroying old VM(s)..."
	cd $(VAGRANT_DIR); vagrant destroy -f $(VM_NAME) || true
