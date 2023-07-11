# Keycloak chart values

- [Homepage](https://www.keycloak.org/)
- [Source (GitHub)](https://github.com/bitnami/charts/tree/main/bitnami/keycloak)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

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

#### `smtp`

SMTP configuration

- `host`: The server host
- `port`: The server port
- `username`: The auth username (and from email)
- `username`: The auth password

#### argocd/oidc

- `cliClientID`: The client ID for cli
- `clientID`: The client ID
- `clientSecret`: The client secret

#### vault/oidc

- `clientID`: The client ID
- `clientSecret`: The client secret
