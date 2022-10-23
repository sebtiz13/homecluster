#!/bin/sh
helm repo add argo-cd "$1" > /dev/null
appVersion=$(helm search repo "argo-cd/$2" --version "$3" -o json | jq -r '.[0].app_version')

# Deploy charts
kubectl apply -n "$4" -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=$appVersion" > /dev/null

# Patch CRDs (for allow helm to modify it)
for crd in "applications.argoproj.io" "applicationsets.argoproj.io" "appprojects.argoproj.io"
do
  kubectl label --overwrite crd "$crd" app.kubernetes.io/managed-by=Helm > /dev/null
  kubectl annotate --overwrite crd "$crd" meta.helm.sh/release-namespace="$4" > /dev/null
  kubectl annotate --overwrite crd "$crd" meta.helm.sh/release-name="$5" > /dev/null
done
