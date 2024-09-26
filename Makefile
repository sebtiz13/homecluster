.PHONY: help init validate cleanup cluster vagrant
.SILENT:
.DEFAULT_GOAL: help

ANSIBLE_DIR := ./ansible
VAGRANT_DIR := ./vagrant
ENVIRONMENT := production
STEP := site
# renovate: datasource=github-releases depName=mike-engel/jwt-cli
JWT_VERSION := 6.1.1

ifndef VERBOSE
MAKEFLAGS += --no-print-directory
endif

help: ## Display this help screen
	grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
_validate-vm:
ifndef VM_NAME
	$(error VM_NAME is required for this command)
endif

init: ## Init environment
	echo "Creating python virual environment and install required packages..."
	cd $(ANSIBLE_DIR); python -m venv .venv
	cd $(ANSIBLE_DIR); .venv/bin/pip install -r requirements.txt
	echo "Installing ansible modules..."
	cd $(ANSIBLE_DIR); .venv/bin/ansible-galaxy install -r requirements.yaml
	echo "Creating required folders..."
	mkdir -p $(ANSIBLE_DIR)/.bin
	mkdir -p ./out/kubeconfig
	mkdir -p ./out/credentials/{dev,production}
ifeq ($(ENVIRONMENT), dev)
	mkdir -p $(VAGRANT_DIR)/.vagrant/ca
endif
	echo "Download JWT tool..."
	curl -L --progress-bar https://github.com/mike-engel/jwt-cli/releases/download/$(JWT_VERSION)/jwt-linux.tar.gz \
		-o $(ANSIBLE_DIR)/.bin/jwt-linux.tar.gz \
		&& tar -xf $(ANSIBLE_DIR)/.bin/jwt-linux.tar.gz -C $(ANSIBLE_DIR)/.bin \
		&& chmod +x $(ANSIBLE_DIR)/.bin/jwt \
		&& rm $(ANSIBLE_DIR)/.bin/jwt-linux.tar.gz

cleanup: ## Cleanup development environment
	echo "Clean development environment..."
	cd $(VAGRANT_DIR); vagrant destroy || true
	CAROOT=$(VAGRANT_DIR)/.vagrant/ca mkcert -uninstall
	rm -rf $(VAGRANT_DIR)/.vagrant
	rm -rf ./out/kubeconfig/*.dev.yaml
	rm -rf ./out/credentials/dev
	rm -rf $(ANSIBLE_DIR)/{.venv,.bin}

cluster: ## All-in-one command for cluster deployment
ifndef DOMAIN_NAME
	$(error DOMAIN_NAME is required for this command)
endif
	$(MAKE) init
	echo "Create credentials..."
	./scripts/gen-credentials.sh
	$(MAKE) provision
provision: ## Provisioning machines
ifndef DOMAIN_NAME
	$(error DOMAIN_NAME is required for this command)
endif
	echo "Provisioning cluster(s)"
	./scripts/_ansible.sh "$(ANSIBLE_DIR)" production "$(DOMAIN_NAME)" "$(STEP)"

test-cluster: ## [DEV] All-in-one command for cluster deployment
	$(MAKE) init ENVIRONMENT=dev
	echo "Create credentials..."
	ENVIRONMENT=dev ./scripts/gen-credentials.sh
	$(MAKE) vm-create
	$(MAKE) test-provision
test-provision: ## [DEV] Provisioning machines
	echo "Provisioning VM(s)"
ifndef VM_NAME
	./scripts/_ansible.sh "$(ANSIBLE_DIR)" dev "$(or $(DOMAIN_NAME), local.vm)" \
		"$(STEP)"
else
	./scripts/_ansible.sh "$(ANSIBLE_DIR)" dev "$(or $(DOMAIN_NAME), local.vm)" \
		"--limit $(VM_NAME)" "$(STEP)"
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
	$(MAKE) _validate-vm
	cd $(VAGRANT_DIR); vagrant ssh $(VM_NAME)
vm-reload: ## Reload vagrant VM
	echo "Reload VM(s)..."
	cd $(VAGRANT_DIR); vagrant reload $(VM_NAME)
vagrant: ## (Re)create vagrant VM
	$(MAKE) vm-destroy
	$(MAKE) vm-create
