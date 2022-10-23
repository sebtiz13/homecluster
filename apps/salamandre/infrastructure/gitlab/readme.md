# GitLab chart values

- [Homepage](https://gitlab.com/)
- [Source (GitHub)](https://gitlab.com/gitlab-org/charts/gitlab)

## Vault secrets

The secrets keys need to exist for deploy the app

### `gitlab/database`

- `host`: The server hostname
- `port`: The server port
- `user`: The credential username
- `password`: The credential password
- `database`: The database name

### `gitlab/s3`

- `endpoint`: The endpoint domain
- `region`: The region of buckets
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

### `giltab/oidc`

- `issuer`: The issuer URL (eg. `https://sso.local.vm/realm/developer`)
- `clientID`: The client ID
- `clientSecret`: The client secret

### `gitlab/runner`

- `registrationToken`: The token for auto register runner
