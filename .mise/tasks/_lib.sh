#!/usr/bin/env bash
#MISE hide=true
ERROR_PREFIX="\033[0;31mERROR\033[0m"

# Validate DOMAIN_NAME
# Usage: validate_args <environment> [domain]
validate_args() {
  local env="$1"
  local domain="$2"
  # Fallback domain in dev to apply regex
  if [[ "$env" == "dev" && -z "$domain" ]]; then
    domain="${VM_DOMAIN_NAME:-local.vm}"
  fi

  if [[ "$env" == "production" && -z "$domain" ]]; then
    echo -e "${ERROR_PREFIX} <domain> is required in production environment" >&2
    exit 1
  fi

  local regex='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}$'
  if [[ ! "$domain" =~ $regex ]]; then
    echo -e "${ERROR_PREFIX} <domain> ($domain) is not an valid domain name" >&2
    exit 1
  fi
}

# Resolve domain name with development fallback
# Usage: resolve_domain <environment> [domain]
resolve_domain() {
  local env="$1"
  local domain="$2"

  if [[ "$env" == "dev" && -z "$domain" ]]; then
    echo "${VM_DOMAIN_NAME:-local.vm}"
  else
    echo "$domain"
  fi
}

# Build --limit flag if host is defined
# Usage: limit_flag [hostname]
limit_flag() {
  local host="$1"
  if [[ -n "$host" ]]; then
    echo "--limit localhost,$host"
  fi
}

# Run ansible playbook
# Usage: run_ansible <step> <environment> [domain] [rest]
run_ansible() {
  local git_branch
  local rest

  # Handle rest arg
  if [[ "${3:-}" == -* ]]; then
    IFS=" " read -r -a rest <<< "${3:-}"
  else
    git_branch=$(git rev-parse --abbrev-ref HEAD)
    # shellcheck disable=SC2089
    IFS=" " read -r -a rest <<< "${4:-}"
    rest+=(--extra-vars "root_domain=$3" --extra-vars "git_branch=$git_branch")
  fi

  cd "$ANSIBLE_DIR" && ansible-playbook --inventory "inventories/$2" "${rest[@]}" "$1.yaml"
  cd - || return
}

# Check if an command is installed
# Usage: check_command <command>
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "You should install $1 to generate credentials"
    exit 1
  fi
}
