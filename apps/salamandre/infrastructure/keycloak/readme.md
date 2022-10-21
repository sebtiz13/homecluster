# ArgoCD chart values

- [Homepage](https://argo-cd.readthedocs.io/)
- [Source (GitHub)](https://github.com/argoproj/argo-helm)

## Vault secrets

The secrets keys need to exist for deploy the app

### keycloak/auth

Admin user informations

- `adminUser`: The username
- `adminPassword`: The password

### keycloak/database

Database informations

- `host`: The server hostname
- `port`: The server port
- `user`: The credential username
- `password`: The credential password
- `database`: The database name

### Dependencies

#### argocd/oidc

- `cliClientID`: The client ID for cli
- `clientID`: The client ID
- `clientSecret`: The client secret

#### vault/oidc

- `clientID`: The client ID
- `clientSecret`: The client secret
