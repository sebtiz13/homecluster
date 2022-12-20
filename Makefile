.PHONY: help init validate cleanup cluster vagrant
.SILENT:
.DEFAULT_GOAL= help

ANSIBLE_DIR := ./ansible
VAGRANT_DIR := ./vagrant

help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
_validate-vm:
ifndef VM_NAME
	$(error VM_NAME is required for this command)
endif

init: ## Init environment
	cd $(ANSIBLE_DIR); ansible-galaxy install -r requirements.yaml
	cd $(ANSIBLE_DIR); pip install -r requirements.txt
	mkdir -p ./out/kubeconfig
	mkdir -p ./out/credentials/{dev,prod}
	mkdir -p $(VAGRANT_DIR)/.vagrant/{ca,manifests}

cleanup: ## Cleanup development environment
	echo "Clean development environment..."
	cd $(VAGRANT_DIR); vagrant destroy || true
	CAROOT=$(VAGRANT_DIR)/.vagrant/ca mkcert -uninstall
	rm -r $(VAGRANT_DIR)/.vagrant/{ca,manifests}
	rm -r ./out/kubeconfig/*.dev.yaml
	rm -r ./out/credentials/dev

cluster: ## All-in-one command for cluster deployment
ifndef DOMAIN_NAME
	$(error DOMAIN_NAME is required for this command)
endif
	make init --no-print-directory
	echo "Create credentials..."
	./scripts/gen-credentials.sh
	make provision --no-print-directory
provision: ## Provisioning machines
	echo "Provisioning cluster(s)"
	./scripts/ansible.sh

test-cluster: ## [DEV] All-in-one command for cluster deployment
	make init --no-print-directory
	echo "Create credentials..."
	ENVIRONMENT=dev ./scripts/gen-credentials.sh
	make vm-manifests --no-print-directory
	make vm-create --no-print-directory
	make test-provision --no-print-directory
test-provision: ## [DEV] Provisioning machines
	echo "Provisioning VM(s)"
ifndef VM_NAME
	ENVIRONMENT=dev ./scripts/ansible.sh
else
	ENVIRONMENT=dev ./scripts/ansible.sh "--limit $(VM_NAME)"
endif

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
vm-manifests: ## Build manifests for VM
	echo "Generate applications manifests..."
	MANIFESTS_PATH=$(VAGRANT_DIR)/.vagrant/manifests ENVIRONMENT=dev ./scripts/apps/all.sh ./scripts/apps/build.sh
