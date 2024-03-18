# Updates

## Operating System

The underlying cluster nodes can be fully updated by using the following Ansible playbook:

```sh
> make provision STEP=setup
```

> Info: for update vm replace `provision` by `test-provision`.

## Kubernetes

Currently for updating kubernetes you need to run same command as [Operating System](#operating-system).

## Services

Updates of the running services and containers are done via Pull Requests by **Renovate Bot** which fits perfectly into the GitOps based workflow of Flux. It continuously checks the following data sources for new versions and creates Pull Requests to adapt them inside the cluster:

- Container images
- Helm Charts
- GitHub repositories
- GitHub releases
