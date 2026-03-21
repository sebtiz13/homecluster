# Post-installation

## Backup secrets

Save the following files to a safe location like a password manager (if you're using the sandbox, you can skip this step):

- `./out/kubeconfig/salamandre.production.yaml`
- `./out/kubeconfig/baku.production.yaml`
- `./out/credentials/production/*` (for `openbao.json` only `root_token` and `unseal_keys_b64` is important)

## Admin credentials

Admin credentials can be retrieve with :

```sh
mise run credentials:get <environment> <application>
```
