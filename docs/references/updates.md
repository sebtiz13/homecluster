# Updates

## Operating System

The underlying cluster nodes can be fully updated by using the following command:

```sh
mise run node:setup <environment>
```

## Kubernetes

Currently for updating kubernetes you need to run same command as [Operating System](#operating-system).

## CRDS

After updating victoria-metrics-operator you need to update CRDs with the followed command:

```sh
helm show crds victoriametrics/victoria-metrics-k8s-stack --version x.x.x | kubectl apply -f - --server-side --force-conflicts
```

## Services

Updates of the running services and containers are done via Pull Requests by **Renovate Bot** which fits perfectly into the GitOps based workflow of Flux. It continuously checks the following data sources for new versions and creates Pull Requests to adapt them inside the cluster:

- Container images
- Helm Charts
- GitHub repositories
- GitHub releases
