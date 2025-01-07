#!/bin/sh
cd "$1" || exit

rest=""
if [ -n "$4" ]; then
  rest="--limit localhost,$4"
fi

# shellcheck disable=SC1091
. ./.venv/bin/activate
# shellcheck disable=SC2086
ansible-playbook --inventory "inventories/$2" \
	--ask-become-pass $rest "vms_$3.yaml"
