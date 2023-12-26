#!/bin/sh
if [ -z "$1" ]; then
  echo "Usage: create-db-user <username>"
  exit 1
fi

createDb() {
  sudo -u postgres psql -c "\set AUTOCOMMIT on\n
CREATE DATABASE $1;
CREATE USER $1 WITH ENCRYPTED PASSWORD '$2';
ALTER DATABASE $1 OWNER TO $1;"
}

password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd "a-zA-Z0-9" | head -c 16)
if createDb "$1" "$password"; then
  echo "New User: $1"
  echo "With password: $password"
fi
