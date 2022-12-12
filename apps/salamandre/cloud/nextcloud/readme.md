# Nextcloud chart values

- [Homepage](https://nextcloud.com/)
- [Source (GitHub)](https://github.com/nextcloud/helm/tree/master/charts/nextcloud)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

### nextcloud/auth

Admin user informations

- `adminUser`: The username
- `adminPassword`: The password
- `collaboraAdminUser`: The collabora username
- `collaboraAdminPassword`: The collabora password

### nextcloud/database

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
