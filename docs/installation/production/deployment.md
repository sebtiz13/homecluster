# Production deployment

> ⚠️ Please read the [prerequisites](./prerequisites.md) before !

## Commands

### Variables

- `SERVER` (possible values: `salamandre`, `baku`): the server name

### All-in-one

```sh
make cluster SERVER=<name>
```

### Deploy cluster

Deploy the cluster

```sh
make apply SERVER=<name>
```

## GitLab Agent

For deploy GitLab Agent please follow [this section](../gitlab-agent.md).
