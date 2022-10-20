#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200
vault login -no-print "${token}"

%{ for path, values in secrets ~}
vault kv put argocd/${path} ${values}
%{ endfor ~}
