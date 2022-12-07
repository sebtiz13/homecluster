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

mkdir -p "./out/credentials/salamandre/${ENVIRONMENT}"
mkdir -p "./out/credentials/baku/${ENVIRONMENT}"

##
# Salamandre credentials
##
cat - > "./out/credentials/salamandre/${ENVIRONMENT}/admin_passwords.yaml" <<EOF
argocd: "$(randpw 16)"
keycloak: "$(randpw 16)"
minio: "$(randpw 16)"
gitlab: "$(randpw 16)"
EOF

randpw 64 > "./out/credentials/salamandre/${ENVIRONMENT}/gitlab-runner-token"


##
# Baku credentials
##
cat - > "./out/credentials/baku/${ENVIRONMENT}/admin_passwords.yaml" <<EOF
minio: "$(randpw 16)"
EOF
