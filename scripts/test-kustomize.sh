#!/bin/bash
shopt -s globstar nullglob
for pathname in kubernetes/**/kustomization.yaml; do
  if [[ $pathname =~ "wallabag" ]]; then
    continue
  fi

  pathname=$(dirname "$pathname")
  echo -n "[$pathname] "
  kubectl kustomize "$pathname" > /dev/null && echo "Succced !" || exit 1
done
