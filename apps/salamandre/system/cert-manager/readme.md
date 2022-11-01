# Cert manager chart values

- [Homepage](https://cert-manager.io/)
- [Source (GitHub)](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

### `cert-manager/ovh` (**REQUIRED** for production environment)

- `applicationKey`: The OVH application key.
- `applicationSecret`: The OVH application secret
- `consumerKey`: Your OVH consumer key
