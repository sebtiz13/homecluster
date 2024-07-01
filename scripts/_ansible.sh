#!/bin/sh
cd "$1" || exit

git_branch=$(git rev-parse --abbrev-ref HEAD)

# Retrieve rest and step
if [ -z "$5" ]; then
  rest=""
  step=$4
else
  rest=$4
  step=$5
fi

# shellcheck disable=SC1091
. ./.venv/bin/activate
# shellcheck disable=SC2086
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook --inventory "inventories/$2" \
  --extra-vars "root_domain=$3" --extra-vars "git_branch=$git_branch" \
	$rest "$step.yaml"
