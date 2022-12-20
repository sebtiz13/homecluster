# Roadmap

> Current status: **ALPHA**

## Alpha requirement

Good enough for tinkering.

- [x] Automated bare metal provisioning
  - [x] Set up ZFS pool
  - [x] Set up PostgreSQL (on Salamandre)
- [x] Automated cluster creation (k3s)
- [x] Automated application deployment (ArgoCD, on Salamandre)
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

- [x] Automated application sync (GitLab Agent and ArgoCD, on Salamandre)
- [ ] Automated DNS management (update DNS records, on Salamandre)
- [x] Single Sign-On (keycloak, on Salamandre)
- [x] Reasonably secure
  - [x] Automated certificate management (cert-manager, on Salamandre)
  - [x] Declarative secret management (vault and external-secrets, on Salamandre)
  - [x] Replace all default passwords with randomly generated ones
- [x] Backup solution (Barman/ZFS, _Strategy: 3 copies, 2 separate devices, 1 offsite_)
- [ ] Observability (on Baku)
  - [ ] Monitoring
  - [ ] Logging
  - [ ] Alerting
- [x] Core/System applications
  - **Salamandre**
    - [x] Kubed
    - [x] Minio
  - **Baku**
    - [x] Kubed
    - [x] Minio

## Stable requirement

Can be used in "production" (for family).

- [x] A single command to deploy everything
- [x] Fast deployment time (from empty hard drive to running services in under 1 hour)
- [ ] Fully automatic, not just automated
  - [ ] Bare-metal OS rolling upgrade
  - [ ] Kubernetes version rolling upgrade
  - [ ] Application version upgrade (Renovate)
  - [ ] Encrypted backups
  - [x] Self healing
- [x] Minimal dependency on external services
- [x] Additional applications
  - **Salamandre**
    - [x] GitLab (git server and private container registry)
    - [x] Nextcloud
    - [x] Vaultwarden
  - **Baku**
    - [x] Adguard

## Unplanned

Nice to have

- [ ] Addition applications
  - [ ] Plex
- [ ] Serverless ([Knative](https://knative.dev/))
- [ ] Secrets rotation (_currently impossible due to ArgoCD_)
