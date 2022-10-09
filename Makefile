.PHONY: help init validate cleanup cluster vagrant
.SILENT:
.DEFAULT_GOAL= help

TF_SALAMANDRE_DIR := ./terraform/salamandre
TF_BAKU_DIR := ./terraform/baku
VAGRANT_DIR := ./vagrant
SERVER := $(subst .vm,,$(VM_NAME))

ifeq ($(SERVER), salamandre)
	TERRAFORM_DIR := $(TF_SALAMANDRE_DIR)
endif
ifeq ($(SERVER), baku)
	TERRAFORM_DIR := $(TF_SALAMANDRE_DIR)
endif


help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
_validate:
ifeq ("$(wildcard $(TERRAFORM_DIR)/.)",)
	$(error Please specify valid 'SERVER')
endif

init: ## Init environment of Terraform
	make _validate --no-print-directory
	echo "Initializing terraform environment..."
	terraform version
	mkdir -p ./out/kubeconfig
	cd $(TERRAFORM_DIR); terraform init

init-upgrade: ## Init/upgrade environment of Terraform
	make _validate --no-print-directory
	echo "Initializing terraform environment..."
	mkdir -p ./out/kubeconfig
	terraform version
	cd $(TERRAFORM_DIR); terraform init --upgrade

validate: ## Terraform files
	cd $(TF_SALAMANDRE_DIR); terraform validate
	cd $(TS_BAKU_DIR); terraform validate

cleanup: ## Cleanup init an testing environment
	make _validate --no-print-directory
	echo "Remove terraform files..."
	rm -rf $(TF_SALAMANDRE_DIR)/.terraform
	rm -rf $(TS_BAKU_DIR)/.terraform
	echo "Destroying VM(s)..."
	cd $(VAGRANT_DIR); vagrant destroy || true


cluster: ## All-in-one command for cluster deployment
	make init --no-print-directory
	make apply --no-print-directory
apply: ## [terraform] Create or update infrastructure
	make _validate --no-print-directory
	echo "Provisining cluster..."
	cd $(TERRAFORM_DIR); terraform apply -var-file="terraform.tfvars" -auto-approve $(ARGS) && terraform refresh -var-file="terraform.tfvars" $(ARGS)

test-cluster: ## All-in-one command for cluster deployment inside VM
	make init --no-print-directory
	make vm-create --no-print-directory
	sleep 10
	make test-apply --no-print-directory
test-apply: ## [terraform] Create or update infrastructure inside VM
	make _validate --no-print-directory
	echo "Provisining cluster..."
	cd $(TERRAFORM_DIR); terraform apply -var-file="vm.tfvars" -auto-approve $(ARGS) && terraform refresh -var-file="vm.tfvars" $(ARGS)


plan: ## [terraform] Plan of infrastructure
	make _validate --no-print-directory
	cd $(TERRAFORM_DIR); terraform plan -var-file="terraform.tfvars"
test-plan: ## [terraform] Plan of infrastructure inside VM
	make _validate --no-print-directory
	cd $(TERRAFORM_DIR); terraform plan -var-file="vm.tfvars"

vm-create: ## Create vagrant VM
	echo "Creating new VM(s)..."
	cd $(VAGRANT_DIR); vagrant up $(VM_NAME)
vm-destroy: ## Destroying vagrant VM
	echo "Destroying old VM(s)..."
ifndef VM_NAME
	cd $(VAGRANT_DIR); vagrant destroy || true
else
	cd $(VAGRANT_DIR); vagrant destroy -f $(VM_NAME) || true
endif
vm-ssh: ## Accessing to VM
ifdef VM_NAME
	$(error VM_NAME is required for this command)
endif
	cd $(VAGRANT_DIR); vagrant ssh $(VM_NAME)
vagrant: ## (Re)create vagrant VM
	make vm-destroy --no-print-directory
	make vm-create --no-print-directory
