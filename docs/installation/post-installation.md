# Post-installation

## Backup secrets

Save the following files to a safe location like a password manager (if you're using the sandbox, you can skip this
step):

- `./out/kubeconfig/salamandre.production.yaml`
- `./out/kubeconfig/baku.production.yaml`
- `./out/credentials.json`

## Admin credentials

- ArgoCD:
  - Username: `admin`
  - Password: run `jq .argocd_admin_password ./out/credentials.json`
- Vault:
  - Root token: run `jq .vault.root_token ./out/credentials.json`
- Keycloak:
  - Username: `admin`
  - Password: run `jq .keycloak_admin_password ./out/credentials.json`
- Minio:
  - Username: `admin`
  - Password: run `jq .minio_admin_password ./out/credentials.json`
