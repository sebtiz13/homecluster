# Minio chart values

- [Homepage](https://min.io/)
- [Source (GitHub)](https://github.com/minio/minio/tree/master/helm/minio)

## Vault secrets

The secrets keys need to exist for deploy the app

### minio/auth

Root user informations

- `rootUser`: The username
- `rootPassword`: The password

### Dependencies

#### `gitlab/s3`

- `accessKey`: The access key
- `accessSecret`: The access secret
- `bucket_artifacts`: The bucket name for artifacts
- `bucket_backups`: The bucket name for backups
- `bucket_depsProxy`: The bucket name for dependencies proxy
- `bucket_packages`: The bucket name for packages
- `bucket_pages`: The bucket name for pages
- `bucket_registry`: The bucket name for registry
- `bucket_runner`: The bucket name for runner
- `bucket_tfState`: The bucket name for Terraform states
- `bucket_uploads`: The bucket name for uploads
- `bucket_lfs`: The bucket name for git LFS (Large File Storage)
