# Terraform commands

## Variables

- `ARGS`: The arguments want added to terraform commands (e.g. `ARGS="-target='module.ssh'"`)

## Init environment

```sh
make init
```

## Init/upgrade environment

```sh
make init-upgrade
```

## Validate terraform files

```sh
make validate
```

## Create or update infrastructure

- Production

  ```sh
  make apply
  ```

- Development

  ```sh
  make test-apply
  ```

> ⚠️ This command **REQUIRE** `SERVER` OR `VM_NAME` variable.

## Plan changes on infrastructure

- Production

  ```sh
  make plan
  ```

- Development

  ```sh
  make test-plan
  ```

> ⚠️ This command **REQUIRE** `SERVER` OR `VM_NAME` variable.
