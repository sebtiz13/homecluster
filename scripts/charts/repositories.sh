#!/bin/sh
# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo add cert-manager-webhook-ovh-charts https://aureq.github.io/cert-manager-webhook-ovh/
# gitlab
helm repo add gitlab https://charts.gitlab.io/
# nextcloud
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo add chrisingenhaag https://chrisingenhaag.github.io/helm/
# minio
helm repo add minio https://charts.min.io/

# Updat erpo
helm repo update
