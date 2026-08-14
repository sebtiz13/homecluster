---
name: Homecluster Project Architecture
alwaysApply: true
---

# Project Architecture

This repository contains the homelab infrastructure managed as code. The local workspace is the source of truth.

## Source of Truth

- Inspect the relevant local files before making architectural or implementation claims.
- Trust the current workspace over this document when they disagree.
- Report discrepancies instead of silently correcting them.
- Do not invent directories, files, versions, resources, or deployment methods.

## Repository Structure

- `.continue/`: Continue rules and local assistant configuration.
- `.mise/tasks/`: Mise tasks for project management, deployment, destruction, backups, and other operations.
- `ansible/`: VM lifecycle, machine provisioning, and cluster provisioning.
- `docs/`: Operational documentation, procedures, and restoration instructions.
- `kubernetes/`: Kubernetes and Flux resources.
  - `base/`: Flux entry points and shared GitOps composition.
  - `config/`: Cluster-level Kubernetes configuration.
  - `core/`: Mandatory platform components, such as Traefik, External Secrets, and ZFS LocalPV.
  - `crds/`: Custom Resource Definitions and related resources.
  - `services/`: Non-mandatory applications, such as Forgejo, Nextcloud and monitoring.
- `scripts/`: CI/CD and repository automation scripts.

Use the actual local directory names and existing conventions. Do not create a directory solely because it is described here.

### Kubernetes Layout

The following directories use the same layout:

- `kubernetes/base/`
- `kubernetes/core/`
- `kubernetes/services/`

Their expected structure is:

```text
/<context>/<environment>/
```

Valid `<context>` values:

- `baku`: Baku-specific resources.
- `salamandre`: Salamandre-specific resources.
- `common`: resources shared by contexts.

Valid `<environment>` values:

- `dev`: development resources.
- `production`: production resources.
- `base`: shared resources for the corresponding context.

Before adding or modifying a resource, determine its context and environment. Prefer `common` for genuinely shared resources and a host-specific context only when the resource depends on Baku or Salamandre.

Do not place production resources under `dev`, or host-specific resources under `common`. Do not assume that `base` means production; inspect the existing Flux composition to determine how it is reconciled.

## Platform Components

- Hosts: Debian with ZFS; compression enabled, deduplication disabled.
- Provisioning: Ansible.
- Kubernetes: K3S, server-only, SQLite datastore, Flannel CNI.
- Storage: OpenEBS ZFS LocalPV (`openebs-zfspv`) and `local-path`.
- GitOps: Flux.
- Database: PostgreSQL 16 managed by CloudNativePG in the `database` namespace.
- Ingress and DNS: Traefik, external-dns, and cert-manager.
- Monitoring: Grafana, VictoriaMetrics, and Alertmanager.
- Notifications: Discord webhook.
- Logs: no centralised logging system.

These are architectural expectations, not proof that a component is currently installed. Verify the local manifests, Ansible files, task definitions, and documentation before relying on them.

## File and Change Conventions

- Preserve the existing file format, directory hierarchy, naming, namespaces, labels, annotations, Kustomizations, Helm values, and dependency ordering.
- Prefer declarative changes through Ansible or Flux over one-off imperative commands.
- Use the existing management layer: Ansible for hosts and provisioning; Flux/Kubernetes manifests for cluster resources; Mise tasks for manual workflows.
- Inspect the relevant local files and name them explicitly before proposing an edit.
- Validate YAML, Ansible, Kustomize, Helm, and task syntax with the project’s existing validation commands before application.
- Respect `.gitignore` and `.continueignore`.
- Do not read, index, display, or modify secrets, private keys, kubeconfigs, tokens, passwords, webhook URLs, database dumps, backups, binaries, generated files, or caches unless explicitly requested.

## Assistant Behaviour

- Ask only the minimum questions required to remove an unsafe ambiguity.
- Prefer simple, robust, maintainable solutions over additional components or abstractions.
- Do not apply production changes automatically.
- For every proposed action, provide:
  1. assumptions: versions, paths, target context/environment, and privileges;
  2. quick analysis based on local files;
  3. commands or exact file changes;
  4. backup and rollback procedure;
  5. risks and operational impact.
- If the required information is not available locally, state what is missing instead of guessing.
