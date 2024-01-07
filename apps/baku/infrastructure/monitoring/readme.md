# VictoriaMetrics stack chart values

- [Homepage](https://victoriametrics.com/)
- [Source (GitHub)](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack)

## Dependencies

- [Grafana](https://grafana.com/)
- [kube-state-metrics (KSM)](https://github.com/kubernetes/kube-state-metrics/)
- [Node exporter](https://github.com/prometheus/node_exporter)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `baku`

### grafana/auth

Admin user informations

- `adminUser`: The username
- `adminPassword`: The password

### grafana/oidc

- `issuer`: The issuer URL (eg. `https://sso.local.vm/realm/developer`)
- `clientID`: The client ID
- `clientSecret`: The client secret
