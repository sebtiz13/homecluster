# VictoriaMetrics stack chart values

- [Homepage](https://victoriametrics.com/)
- [Source (GitHub)](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack)

## Dependencies

- [kube-state-metrics (KSM)](https://github.com/kubernetes/kube-state-metrics/)
- [Node exporter](https://github.com/prometheus/node_exporter)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `baku`

### monitoring/auth

Root user informations

- `vmsingleUser`: The username
- `vmsinglePassword`: The password
