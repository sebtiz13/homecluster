# Roadmap

> Current status: **BETA**

## Alpha requirement

Good enough for tinkering.

- [x] Automated bare metal provisioning
  - [x] Set up ZFS pool
  - [x] Set up PostgreSQL (on Salamandre)
- [x] Automated cluster creation (k3s)
- [x] Automated application deployment (Flux, on Salamandre)
- [x] Only use open-source technologies
- [x] Everything is defined as code
- [x] Core/System applications
  - **Salamandre**
    - [x] OpenEBS
    - [x] Traefik
  - **Baku**
    - [x] OpenEBS
    - [x] Traefik

## Beta requirement

Good enough for tinkering, personal usage and reasonably secure.

- [x] Automated application sync (Flux)
- [x] Automated DNS management (update DNS records, on Salamandre)
- [x] Single Sign-On (Zitadel, on Salamandre)
- [x] Reasonably secure
  - [x] Automated certificate management (cert-manager, on Salamandre)
  - [x] Declarative secret management (OpenBao and external-secrets, on Salamandre)
  - [x] Replace all default passwords with randomly generated ones
- [x] Backup solution (Barman/ZFS)
- [ ] Observability (on Baku)
  - [x] Monitoring
  - [ ] Logging (with [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/))
  - [x] Alerting
- [x] Core/System applications
  - [x] Traefik
  - [x] external-secrets
  - [x] OpenEBS (zfs-localpv)
  - **Salamandre**
    - [x] Postgres
  - **Baku**
    - [x] Minio

## Stable requirement

Can be used in "production" (for family).

- [x] A single command to deploy everything
- [x] Fast deployment time (from empty hard drive to running services in under 1 hour)
- [x] Fully automatic, not just automated
  - [x] Application version upgrade (Renovate)
  - [x] Self healing
- [x] Minimal dependency on external services
- [x] Additional applications
  - **Salamandre**
    - [x] Forgejo (git server and private container registry)
    - [x] Nextcloud
    - [x] Vaultwarden

## Unplanned

Nice to have

- [ ] Addition applications
  - [ ] Plex
  - [ ] Serverless ([Knative](https://knative.dev/))
- [ ] Encrypted backups
- [x] Secrets rotation
