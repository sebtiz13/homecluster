# Production deployment

> ⚠️ Please read the [prerequisites](./prerequisites.md) before !

## Commands

### All-in-one

```sh
DOMAIN_NAME=<domain> make cluster
```

### Only provisioning

```sh
DOMAIN_NAME=<domain> make provision
```

You can precise step with `STEP` argument. This following steps is available :

- `setup`: upgrading operating system and kubernetes
- `k3s_bootstrap`: Deploying applications with flux
- `k3s_configure`: (Re)Configure applications
- `k3s_nuke`: Delete Kubernetes, so it clean all applications
