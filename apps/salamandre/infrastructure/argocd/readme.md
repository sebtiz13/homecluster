# ArgoCD chart values

- [Homepage](https://argo-cd.readthedocs.io/)
- [Source (GitHub)](https://github.com/argoproj/argo-helm)

## Vault secrets

The secrets keys need to exist for deploy the app

### argocd/oidc

- `issuer`: The issuer URL (eg. `https://sso.local.vm/realm/developer`)
- `cliClientID`: The client ID for cli
- `clientID`: The client ID
- `clientSecret`: The client secret
