#!/bin/bash
if ! command -v pwgen  &> /dev/null; then
  echo "You should install pwgen to generate credentials"
  exit 1
fi
if ! command -v yq  &> /dev/null; then
  echo "You should install yq to generate credentials"
  exit 1
fi

ENVIRONMENT=${ENVIRONMENT:-prod}
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  echo "Incorrect environment. Valid value : 'dev' or 'prod'"
  exit 1
fi

DEFAULT_LENGTH=32
randpw () {
  pwgen -cnysB -r "'\"\`" "${1:-$DEFAULT_LENGTH}" 1
}

insert_pwd() {
  if [[ "$(yq "$2" "$1")" = "null" ]]; then
    yq -i "$2 = \"$3\"" "$1"
  fi
}

##
# Salamandre credentials
##
mkdir -p "./out/credentials/salamandre/${ENVIRONMENT}"

# Admin passwords
FILE="./out/credentials/salamandre/${ENVIRONMENT}/admin_passwords.yaml"

touch "$FILE"
insert_pwd "$FILE" .argocd "$(randpw 16)"
insert_pwd "$FILE" .zitadel "$(randpw 16)"
insert_pwd "$FILE" .minio "$(randpw 16)"
insert_pwd "$FILE" .nextcloud "$(randpw 16)"
insert_pwd "$FILE" .collabora "$(randpw 16)"
insert_pwd "$FILE" .forgejo "$(randpw 16)"

# Zitadel masterkey
FILE="./out/credentials/salamandre/${ENVIRONMENT}/zitadel_masterkey"

if [ ! -e "$FILE" ]; then
  pwgen -cn 32 1 > "$FILE"
fi

##
# Baku credentials
##
mkdir -p "./out/credentials/baku/${ENVIRONMENT}"

# Admin passwords
FILE="./out/credentials/baku/${ENVIRONMENT}/admin_passwords.yaml"

touch "$FILE"
insert_pwd "$FILE" .minio "$(randpw 16)"
insert_pwd "$FILE" .grafana "$(randpw 16)"
