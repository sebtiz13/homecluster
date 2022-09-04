.PHONY: help init validate cleanup cluster vagrant
.SILENT:
.DEFAULT_GOAL= help

TERRRAFORM_DIR := ./terraform
VAGRANT_DIR := ./vagrant

help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

init: ## Init environment of Terraform
	echo "Initializing terraform environment..."
	terraform version
ifeq ($(VM_NAME), salamandre.vm)
	cd terraform/salamandre; terraform init
endif
ifeq ($(VM_NAME), baku.vm)
	echo "TODO: is currently not implemented"
endif

init-upgrade: ## Init/upgrade environment of Terraform
	echo "Initializing terraform environment..."
	terraform version
ifeq ($(VM_NAME), salamandre.vm)
	cd terraform/salamandre; terraform init --upgrade
endif
ifeq ($(VM_NAME), baku.vm)
	echo "TODO: is currently not implemented"
endif

validate: ## Terraform files
	cd terraform/salamandre; terraform validate

cleanup: ## Cleanup init an testing environment
	rm -rf terraform/salamandre/.terraform
	make vm-destroy --no-print-directory


cluster: ## All-in-one command for cluster deployment
	make init --no-print-directory
	make apply --no-print-directory
apply: ## [terraform] Create or update infrastructure
	echo "Provisining cluster..."
ifeq ($(VM_NAME), salamandre.vm)
	cd terraform/salamandre; terraform apply -var-file="terraform.tfvars" -auto-approve && terraform refresh
endif
ifeq ($(VM_NAME), baku.vm)
	echo "TODO: is currently not implemented"
endif

test-cluster: ## All-in-one command for cluster deployment inside VM
	make init --no-print-directory
	make vm-create --no-print-directory
	sleep 10
	make test-apply --no-print-directory
test-apply: ## [terraform] Create or update infrastructure  inside VM
	echo "Provisining cluster..."
ifeq ($(VM_NAME), salamandre.vm)
	cd terraform/salamandre; terraform apply -var-file="vm.tfvars" -auto-approve && terraform refresh
endif
ifeq ($(VM_NAME), baku.vm)
	echo "TODO: is currently not implemented"
endif


vm-create: ## Create vagrant VM
	echo "Creating new VM(s)..."
	cd $(VAGRANT_DIR); vagrant up $(VM_NAME)
vm-destroy: ## Destroying vagrant VM
	echo "Destroying old VM(s)..."
	cd $(VAGRANT_DIR); vagrant destroy -f $(VM_NAME) || true
vm-ssh: ## Accessing to VM
	cd $(VAGRANT_DIR); vagrant ssh $(VM_NAME)
vagrant: ## (Re)create vagrant VM
	make vm-destroy --no-print-directory
	make vm-create --no-print-directory
