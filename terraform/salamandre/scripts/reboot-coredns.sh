#!/bin/bash
# Retrieve deployments of `kube-system`
deployments=$(kubectl get deployment -n kube-system 2>&1)
if [[ $? -eq 0 ]]; then
  exit 0
fi

# Reboot coredns if is already started
if [[ "$($deployments | grep coredns | awk '{print $2}')" -eq "1/1" ]]; then
  kubectl rollout restart -n kube-system deployment/coredns
fi
