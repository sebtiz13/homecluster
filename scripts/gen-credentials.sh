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
  pwgen -cnysB -r "'\"\`{}\\|" "${1:-$DEFAULT_LENGTH}" 1
}

insert_pwd() {
  if [[ "$(yq "$2" "$1")" = "null" ]]; then
    yq -i "$2 = \"$3\"" "$1"
  fi
}

mkdir -p "./out/credentials/${ENVIRONMENT}"

##
# Admin passwords
##
FILE="./out/credentials/${ENVIRONMENT}/admin_passwords.yaml"
touch "$FILE"

# Salamandre credentials
insert_pwd "$FILE" .salamandre.zitadel "$(randpw 16)"
insert_pwd "$FILE" .salamandre.nextcloud "$(randpw 16)"
insert_pwd "$FILE" .salamandre.forgejo "$(randpw 16)"

if [[ "$(yq .salamandre.vaultwarden "$FILE")" = "null" ]]; then
  token=$(openssl rand -base64 48)
  insert_pwd "$FILE" .salamandre.vaultwarden.value "$token"
  insert_pwd "$FILE" .salamandre.vaultwarden.salt "$(openssl rand -base64 32)"
  unset "$token"
fi

# Baku credentials
insert_pwd "$FILE" .baku.minio "$(randpw 16)"
insert_pwd "$FILE" .baku.grafana "$(randpw 16)"

##
# Zitadel masterkey
##
FILE="./out/credentials/${ENVIRONMENT}/zitadel_masterkey"
if [ ! -e "$FILE" ]; then
  pwgen -cn 32 1 > "$FILE"
fi

##
# Forgejo runner token
##
FILE="./out/credentials/${ENVIRONMENT}/forgejo_runner_token"
if [ ! -e "$FILE" ]; then
  openssl rand -hex 20 > "$FILE"
fi

##
# Discord webhook url
##
FILE="./out/credentials/${ENVIRONMENT}/discord_webhook_url"
if [ ! -e "$FILE" ]; then
  echo "Enter discord webhook url:"
  IFS= read -r webhookUrl
  echo "$webhookUrl" > "$FILE"
fi
