# GitLab agent chart values

- [Homepage](https://gitlab.com/)
- [Source (GitHub)](https://gitlab.com/gitlab-org/charts/gitlab-agent)

## Vault secrets

The secrets keys need to exist for deploy the app

> **Mount path:** `salamandre`

### `gitlab/agent`

- `token`: The token for connect cluster
- `caCert` (only in VM): The CA certificate
