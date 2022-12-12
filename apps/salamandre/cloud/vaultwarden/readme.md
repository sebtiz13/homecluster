# Vaultwarden chart values

- [Homepage](https://bitwarden.com/)
- [Source (GitHub)](https://github.com/dani-garcia/vaultwarden)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

### vaultwarden/database

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
