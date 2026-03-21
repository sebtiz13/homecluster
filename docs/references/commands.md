# Commands reference

## Setup

Initialize the environment (install Python dependencies, Ansible collections, tools) :

```sh
mise run init
```

## Credentials

Generate credentials for an environment:

```sh
mise run credentials:generate <environment>
```

## Cluster

### All-in-one (recommended)

Generate credentials and deploy the full cluster:

```sh
mise run cluster:deploy <environment> [domain]
```

> `<domain>` is required in production, optional in development (defaults to `local.vm`).

### Step by step

Each command accepts an optional `--host <hostname>` flag to target a single node.

| Step | Commands                                            | Description                                              |
| :--: | --------------------------------------------------- | -------------------------------------------------------- |
|  1   | `mise run node:setup <environment>`                 | Upgrade OS and prepare the machine                       |
|  2   | `mise run cluster:bootstrap <environment> [domain]` | Deploy Flux and CA certificates                          |
|  3   | `mise run cluster:configure <environment> [domain]` | (Re)configure cluster applications                       |
|  ⚠️  | `mise run cluster:nuke <environment> [domain]`      | **Destructive** - delete Kubernetes and all applications |

## Common operations

### Update a node

To upgrade the OS and Kubernetes on one or all nodes:

```sh
# All nodes
mise run node:setup <environment>

# Single node
mise run node:setup <environment> --host <hostname>
```

### Rotate / update credentials

To regenerate credentials (only dynamics like database password) and reapply the configuration:

```sh
# All nodes
mise run cluster:configure <environment>

# Single node
mise run cluster:configure <environment> --host <hostname>
```
