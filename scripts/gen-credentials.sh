#!/bin/bash
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "You should install $1 to generate credentials"
    exit 1
  fi
}

check_command pwgen
check_command openssl
check_command yq

ENVIRONMENT=${ENVIRONMENT:-production}
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "production" ]; then
  echo "Incorrect environment. Valid value : 'dev' or 'production'"
  exit 1
fi

DEFAULT_LENGTH=32
randpw () {
  pwgen -cnysB -r "'\"\`{}\\|" "${1:-$DEFAULT_LENGTH}" 1
}

insert_value() {
  # Create file if not exist because from v4 yq don't create it
  [[ -f $1 ]] || touch $1
  if [[ "$(yq "$2" "$1")" = "null" ]]; then
    yq -i "$2 = \"$3\"" "$1"
  fi
}

mkdir -p "./out/credentials/${ENVIRONMENT}"

##
# Admin passwords
##
FILE="./out/credentials/${ENVIRONMENT}/admin_passwords.yaml"
# Salamandre credentials
insert_value "$FILE" .salamandre.zitadel "$(randpw 16)"
insert_value "$FILE" .salamandre.nextcloud "$(randpw 16)"
insert_value "$FILE" .salamandre.forgejo "$(randpw 16)"

if [[ "$(yq .salamandre.vaultwarden "$FILE")" = "null" ]]; then
  token=$(openssl rand -base64 48)
  insert_value "$FILE" .salamandre.vaultwarden.value "$token"
  insert_value "$FILE" .salamandre.vaultwarden.salt "$(openssl rand -base64 32)"
  unset "$token"
fi

# Baku credentials
insert_value "$FILE" .baku.minio "$(randpw 16)"
insert_value "$FILE" .baku.grafana "$(randpw 16)"

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
FILE="./out/credentials/${ENVIRONMENT}/discord_webhook_url.yaml"
if [ ! -e "$FILE" ]; then
  echo "Enter discord webhook url:"
  IFS= read -r webhookUrl
  insert_value "$FILE" .alerts "$webhookUrl"

  echo "Enter discord webhook url for Watchdog:"
  IFS= read -r webhookUrl
  insert_value "$FILE" .watchdog "$webhookUrl"
fi
