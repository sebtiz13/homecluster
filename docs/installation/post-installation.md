# Post-installation

## Backup secrets

Save the following files to a safe location like a password manager (if you're using the sandbox, you can skip this
step):

- `./out/kubeconfig/salamandre.prod.yaml`
- `./out/kubeconfig/baku.prod.yaml`
- `./out/credentials/prod/*` (for `vault.json` only `root_token` and `unseal_keys_b64` is important)

## Admin credentials

> ⚠️ **Before run command, replace `<env>` by the wanted environment (`dev` or `prod`)**

### Salamandre

- Vault:
  - Root token: run `jq -r .root_token ./out/credentials/<env>/vault.json`
- Zitadel:
  - Username: `admin`
  - Password: run `yq .salamandre.zitadel ./out/credentials/<env>/admin_passwords.yaml`
- Nextcloud:
  - Url: `https://cloud.DOMAIN.TLD/login?direct=1`
  - Username: `admin`
  - Password: run `yq .salamandre.nextcloud ./out/credentials/<env>/admin_passwords.yaml`
- Forgejo:
  - Username: `root`
  - Password: run `yq .salamandre.forgejo ./out/credentials/<env>/admin_passwords.yaml`
- Vaullwarden:
  - Token: run `yq .salamandre.vaultwarden.value ./out/credentials/<env>/admin_passwords.yaml`

### Baku

- Minio:
  - Username: `root`
  - Password: `yq .baku.minio ./out/credentials/<env>/admin_passwords.yaml`
