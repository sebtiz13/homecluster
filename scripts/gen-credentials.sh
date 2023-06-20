#!/bin/bash
ENVIRONMENT=${ENVIRONMENT:-prod}
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  echo "Incorrect environment. Valid value : 'dev' or 'prod'"
  exit 1
fi

DEFAULT_LENGTH=32
DEFAULT_CHARS='a-zA-Z0-9'
randpw () {
  head -c 512 /dev/urandom | LC_CTYPE=C tr -cd "${2:-$DEFAULT_CHARS}" | head -c "${1:-$DEFAULT_LENGTH}"
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
insert_pwd "$FILE" .keycloak "$(randpw 16)"
insert_pwd "$FILE" .minio "$(randpw 16)"
insert_pwd "$FILE" .gitlab "$(randpw 16)"
insert_pwd "$FILE" .nextcloud "$(randpw 16)"
insert_pwd "$FILE" .collabora "$(randpw 16)"

##
# Baku credentials
##
mkdir -p "./out/credentials/baku/${ENVIRONMENT}"

# Admin passwords
FILE="./out/credentials/baku/${ENVIRONMENT}/admin_passwords.yaml"

touch "$FILE"
insert_pwd "$FILE" .minio "$(randpw 16)"
insert_pwd "$FILE" .adguard "$(randpw 16)"
