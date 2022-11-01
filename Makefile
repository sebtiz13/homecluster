.PHONY: help init validate cleanup cluster vagrant
.SILENT:
.DEFAULT_GOAL= help

TF_SALAMANDRE_DIR := ./terraform/salamandre
TF_BAKU_DIR := ./terraform/baku
VAGRANT_DIR := ./vagrant
MANIFESTS_DIR := ./out/manifests
SERVER := $(subst .vm,,$(VM_NAME))

ifeq ($(SERVER), salamandre)
	TERRAFORM_DIR := $(TF_SALAMANDRE_DIR)
endif
ifeq ($(SERVER), baku)
	TERRAFORM_DIR := $(TF_BAKU_DIR)
endif


help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
_validate:
ifeq ("$(wildcard $(TERRAFORM_DIR)/.)",)
	$(error Please specify valid 'SERVER')
endif
_validate-vm:
ifndef VM_NAME
	$(error VM_NAME is required for this command)
endif

init: ## Init environment of Terraform
	echo "Initializing terraform environment..."
	terraform version
	mkdir -p ./out/kubeconfig
	cd $(TF_SALAMANDRE_DIR); terraform init
	cd $(TF_BAKU_DIR); terraform init

init-upgrade: ## Init/upgrade environment of Terraform
	echo "Initializing terraform environment..."
	mkdir -p ./out/kubeconfig
	terraform version
	cd $(TF_SALAMANDRE_DIR); terraform init --upgrade
	cd $(TF_BAKU_DIR); terraform init --upgrade

validate: ## Terraform files
	cd $(TF_SALAMANDRE_DIR); terraform validate
	cd $(TF_BAKU_DIR); terraform validate

cleanup: ## Cleanup init an testing environment
	make _validate --no-print-directory
	echo "Remove terraform files..."
	rm -rf $(TF_SALAMANDRE_DIR)/.terraform
	rm -rf $(TF_BAKU_DIR)/.terraform
	echo "Destroying VM(s)..."
	cd $(VAGRANT_DIR); vagrant destroy || true
	CAROOT=$(VAGRANT_DIR)/.vagrant/ca mkcert -uninstall


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
	make vm-manifests --no-print-directory
	echo "Provisining cluster..."
	cd $(TERRAFORM_DIR); terraform apply -var-file="vm.tfvars" -auto-approve $(ARGS) && terraform refresh -var-file="vm.tfvars" $(ARGS)


plan: ## [terraform] Plan of infrastructure
	make _validate --no-print-directory
	cd $(TERRAFORM_DIR); terraform plan -var-file="terraform.tfvars" $(ARGS)
test-plan: ## [terraform] Plan of infrastructure inside VM
	make _validate --no-print-directory
	cd $(TERRAFORM_DIR); terraform plan -var-file="vm.tfvars" $(ARGS)


vm-create: ## Create vagrant VM
ifneq ("$(wildcard $(VAGRANT_DIR)/.vagrant/ca/rootCA.pem)",)
	CAROOT=$(VAGRANT_DIR)/.vagrant/ca mkcert -install
endif
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
	make _validate-vm --no-print-directory
	cd $(VAGRANT_DIR); vagrant ssh $(VM_NAME)
vm-reload: ## Reload vagrant VM
	echo "Reload VM(s)..."
	cd $(VAGRANT_DIR); vagrant reload $(VM_NAME)
vagrant: ## (Re)create vagrant VM
	make vm-destroy --no-print-directory
	make vm-create --no-print-directory
vm-init-state: ## Make an snapshot with only postgresql, zfs and k3s installed
	make _validate-vm --no-print-directory
	make vagrant --no-print-directory
ifeq ($(VM_NAME), salamandre.vm)
	make test-apply --no-print-directory ARGS="--target=module.k3s_install --target=module.ssh --target=null_resource.postgresql_install"
endif
ifeq ($(VM_NAME), baku.vm)
	make test-apply --no-print-directory ARGS="--target=module.k3s_install --target=module.ssh --target=module.zfs"
endif
	cd $(VAGRANT_DIR); vagrant snapshot save $(VM_NAME) init-state
	cp $(TERRAFORM_DIR)/terraform.tfstate ./out/$(SERVER).tfstate
vm-reset-state: ## Restore the initial state of VM (from `vm-init-state`)
	make _validate-vm --no-print-directory
	cd $(VAGRANT_DIR); vagrant snapshot restore $(VM_NAME) init-state --no-provision
	rm $(TERRAFORM_DIR)/terraform.tfstate.backup
	cp ./out/$(SERVER).tfstate $(TERRAFORM_DIR)/terraform.tfstate
vm-manifests: ## Build manifests for VM
	MANIFESTS_PATH=$(MANIFESTS_DIR) ENVIRONMENT=vm ./scripts/apps/all.sh ./scripts/apps/build.sh
