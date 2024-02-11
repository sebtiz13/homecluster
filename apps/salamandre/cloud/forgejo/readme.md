# Forgejo chart values

- [Homepage](https://forgejo.org/)
- [Source (GitHub)](https://codeberg.org/forgejo/forgejo)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

### `forgejo/auth`

Admin user informations

- `adminUser`: The username
- `adminPassword`: The password

### `forgejo/database`

- `host`: The server hostname
- `port`: The server port
- `user`: The credential username
- `password`: The credential password
- `database`: The database name

### `forgejo/oidc`

- `issuer`: The issuer URL (eg. `https://sso.local.vm/realm/developer`)
- `clientID`: The client ID
- `clientSecret`: The client secret

### `forgejo/runner`

Actions runner informations

- `token`: The registration token

### Dependencies

#### `smtp`

SMTP configuration

- `host`: The server host
- `port`: The server port
- `username`: The auth username (and from email)
- `password`: The auth password
