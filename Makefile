.PHONY: help init validate cleanup cluster vagrant
.SILENT:
.DEFAULT_GOAL= help

TERRRAFORM_DIR := ./terraform
TF_SALAMANDRE_DIR := $(TERRRAFORM_DIR)/salamandre
TF_BAKU_DIR := $(TERRRAFORM_DIR)/baku
VAGRANT_DIR := ./vagrant

help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

init: ## Init environment of Terraform
	echo "Initializing terraform environment..."
	terraform version
	mkdir -p ./out/kubeconfig
ifeq ($(VM_NAME), salamandre.vm)
	cd $(TF_SALAMANDRE_DIR); terraform init
endif
ifeq ($(VM_NAME), baku.vm)
	cd $(TF_BAKU_DIR); terraform init
endif

init-upgrade: ## Init/upgrade environment of Terraform
	echo "Initializing terraform environment..."
	mkdir -p ./out/kubeconfig
	terraform version
ifeq ($(VM_NAME), salamandre.vm)
	cd $(TF_SALAMANDRE_DIR); terraform init --upgrade
endif
ifeq ($(VM_NAME), baku.vm)
	cd $(TF_BAKU_DIR); terraform init --upgrade
endif

validate: ## Terraform files
	cd $(TF_SALAMANDRE_DIR); terraform validate

cleanup: ## Cleanup init an testing environment
	rm -rf $(TF_SALAMANDRE_DIR)/.terraform
	make vm-destroy --no-print-directory


cluster: ## All-in-one command for cluster deployment
	make init --no-print-directory
	make apply --no-print-directory
apply: ## [terraform] Create or update infrastructure
	echo "Provisining cluster..."
ifeq ($(VM_NAME), salamandre.vm)
	cd $(TF_SALAMANDRE_DIR); terraform apply -var-file="terraform.tfvars" -auto-approve && terraform refresh -var-file="terraform.tfvars"
endif
ifeq ($(VM_NAME), baku.vm)
	cd $(TF_BAKU_DIR); terraform apply -var-file="terraform.tfvars" -auto-approve && terraform refresh -var-file="terraform.tfvars"
endif

test-cluster: ## All-in-one command for cluster deployment inside VM
	make init --no-print-directory
	make vm-create --no-print-directory
	sleep 10
	make test-apply --no-print-directory
test-apply: ## [terraform] Create or update infrastructure inside VM
	echo "Provisining cluster..."
ifeq ($(VM_NAME), salamandre.vm)
	cd $(TF_SALAMANDRE_DIR); terraform apply -var-file="vm.tfvars" -auto-approve && terraform refresh -var-file="vm.tfvars"
endif
ifeq ($(VM_NAME), baku.vm)
	cd $(TF_BAKU_DIR); terraform apply -var-file="vm.tfvars" -auto-approve && terraform refresh -var-file="vm.tfvars"
endif


plan: ## [terraform] Plan of infrastructure
ifeq ($(VM_NAME), salamandre.vm)
	cd $(TF_SALAMANDRE_DIR); terraform plan -var-file="terraform.tfvars"
endif
ifeq ($(VM_NAME), baku.vm)
	cd $(TF_BAKU_DIR); terraform plan -var-file="terraform.tfvars"
endif
test-plan: ## [terraform] Plan of infrastructure inside VM
ifeq ($(VM_NAME), salamandre.vm)
	cd $(TF_SALAMANDRE_DIR); terraform plan -var-file="vm.tfvars"
endif
ifeq ($(VM_NAME), baku.vm)
	cd $(TF_BAKU_DIR); terraform plan -var-file="vm.tfvars"
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
