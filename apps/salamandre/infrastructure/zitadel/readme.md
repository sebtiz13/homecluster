# Zitadel chart values

- [Homepage](https://zitadel.com/)
- [Source (GitHub)](https://github.com/zitadel/zitadel-charts)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

### zitadel/masterkey

Master key value

- `value`: The master key

### zitadel/database

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
- `password`: The auth password
