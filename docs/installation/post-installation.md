# Post-installation

## Backup secrets

Save the following files to a safe location like a password manager (if you're using the sandbox, you can skip this
step):

- `./out/kubeconfig/salamandre.prod.yaml`
- `./out/kubeconfig/baku.prod.yaml`
- `./out/credentials/salamandre/prod/*` (for `vault.json` only `root_token` and `unseal_keys_b64` is important)
- `./out/credentials/baku/prod/*`

## Admin credentials

> ⚠️ **Before run command, replace `<env>` by the wanted environment (`dev` or `prod`)**

### Salamandre

- ArgoCD:
  - Username: `admin`
  - Password: run `yq .argocd ./out/credentials/salamandre/<env>/admin_passwords.yaml`
- Vault:
  - Root token: run `jq -r .root_token ./out/credentials/salamandre/<env>/vault.json`
- Zitadel:
  - Username: `admin`
  - Password: run `yq .zitadel ./out/credentials/salamandre/<env>/admin_passwords.yaml`
- Minio:
  - Username: `root`
  - Password: `yq .minio ./out/credentials/salamandre/<env>/admin_passwords.yaml`
- Nextcloud:
  - Username: `admin`
  - Password: run `yq .nextcloud ./out/credentials/salamandre/<env>/admin_passwords.yaml`
- Forgejo:
  - Username: `root`
  - Password: run `yq .forgejo ./out/credentials/salamandre/<env>/admin_passwords.yaml`

### Baku

- Minio:
  - Username: `root`
  - Password: `yq .minio ./out/credentials/baku/<env>/admin_passwords.yaml`
