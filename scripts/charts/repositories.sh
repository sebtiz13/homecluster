#!/bin/sh
# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo add cert-manager-webhook-ovh-charts https://aureq.github.io/cert-manager-webhook-ovh/
# gitlab
helm repo add gitlab https://charts.gitlab.io/

# Wait repository fetched
sleep 5
