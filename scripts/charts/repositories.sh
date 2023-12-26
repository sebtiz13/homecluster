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
# monitoring
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add vm https://victoriametrics.github.io/helm-charts/
# zitadel
helm repo add minio https://charts.zitadel.com/

# Update repo
helm repo update
