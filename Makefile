.PHONY: help init validate cleanup cluster
.SILENT:
.DEFAULT_GOAL: help

ANSIBLE_DIR := ./ansible
OUT_DIR := ./out
ENVIRONMENT := production
STEP := site
# renovate: datasource=github-releases depName=mike-engel/jwt-cli
JWT_VERSION := 6.2.0

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
	cd $(ANSIBLE_DIR); python -m venv --system-site-packages .venv
	cd $(ANSIBLE_DIR); .venv/bin/pip install -r requirements.txt
	echo "Installing ansible modules..."
	cd $(ANSIBLE_DIR); .venv/bin/ansible-galaxy install -r requirements.yaml
	echo "Creating required folders..."
	mkdir -p $(ANSIBLE_DIR)/.bin
	mkdir -p $(OUT_DIR)/kubeconfig
	mkdir -p $(OUT_DIR)/credentials/{dev,production}
ifeq ($(ENVIRONMENT), dev)
	mkdir -p $(OUT_DIR)/vms
endif
	echo "Download JWT tool..."
	curl -L --progress-bar https://github.com/mike-engel/jwt-cli/releases/download/$(JWT_VERSION)/jwt-linux.tar.gz \
		-o $(ANSIBLE_DIR)/.bin/jwt-linux.tar.gz \
		&& tar -xf $(ANSIBLE_DIR)/.bin/jwt-linux.tar.gz -C $(ANSIBLE_DIR)/.bin \
		&& chmod +x $(ANSIBLE_DIR)/.bin/jwt \
		&& rm $(ANSIBLE_DIR)/.bin/jwt-linux.tar.gz

cleanup: ## Cleanup development environment
	echo "Clean development environment..."
	CAROOT=$(OUT_DIR)/vms mkcert -uninstall
	rm -rf $(OUT_DIR)/kubeconfig/*.dev.yaml
	rm -rf $(OUT_DIR)/credentials/dev
	rm -rf $(OUT_DIR)/vms
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
	echo "Waiting VMs start..."
	sleep 20
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

vm-create: ## Create VM
ifneq ("$(wildcard $(OUT_DIR)/vms/rootCA.pem)",)
	CAROOT=$(OUT_DIR)/vms mkcert -install
endif
	echo "Creating new VM(s)..."
	./scripts/_ansible-vm.sh "$(ANSIBLE_DIR)" dev create $(VM_NAME)
vm-destroy: ## Destroying VM
	echo "Destroying old VM(s)..."
	./scripts/_ansible-vm.sh "$(ANSIBLE_DIR)" dev destroy $(VM_NAME)
vm-recreate: ## (Re)create VM
	$(MAKE) vm-destroy
	$(MAKE) vm-create
