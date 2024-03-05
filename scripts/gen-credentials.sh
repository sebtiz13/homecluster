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

mkdir -p "./out/credentials/${ENVIRONMENT}"

# Admin passwords
FILE="./out/credentials/${ENVIRONMENT}/admin_passwords.yaml"
touch "$FILE"

##
# Salamandre credentials
##
insert_pwd "$FILE" .salamandre.zitadel "$(randpw 16)"
insert_pwd "$FILE" .salamandre.minio "$(randpw 16)"
insert_pwd "$FILE" .salamandre.nextcloud "$(randpw 16)"
insert_pwd "$FILE" .salamandre.collabora "$(randpw 16)"
insert_pwd "$FILE" .salamandre.forgejo "$(randpw 16)"
insert_pwd "$FILE" .salamandre.vaultwarden "$(randpw 16)"

##
# Baku credentials
##
insert_pwd "$FILE" .baku.minio "$(randpw 16)"
insert_pwd "$FILE" .baku.grafana "$(randpw 16)"

# Zitadel masterkey
FILE="./out/credentials/${ENVIRONMENT}/zitadel_masterkey"
if [ ! -e "$FILE" ]; then
  pwgen -cn 32 1 > "$FILE"
fi

# Zitadel masterkey
FILE="./out/credentials/${ENVIRONMENT}/forgejo_runner_token"
if [ ! -e "$FILE" ]; then
  openssl rand -hex 20 > "$FILE"
fi
