# Production deployment

> ⚠️ Please read the [prerequisites](./prerequisites.md) before !

## Commands

### All-in-one

```sh
DOMAIN_NAME=<domain> make cluster
```

### Only provisioning

```sh
DOMAIN_NAME=<domain> make provision
```

#### Exclude applications

You can disable some applications by specify environment variable `ANSIBLE_SKIP_TAGS` with one or more next tags.
The apps tags :

- `oidc` (for disable zitadel)
- `forgejo`

_example_: `ANSIBLE_SKIP_TAGS=oidc,forgejo make test-cluster`, this deploy all cluster but without oidc and forgejo applications

## GitLab Agent

For deploy GitLab Agent please follow [this section](../gitlab-agent.md).
