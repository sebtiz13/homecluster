# Roadmap

> Current status: **BETA**

## Beta requirement

Good enough for tinkering and personal usage, and reasonably secure.

- [x] Automated bare metal provisioning
  - [x] Set up ZFS pool
  - [x] Set up PostgreSQL
- [x] Automated cluster creation (k3s)
- [x] Automated application deployment (ArgoCD and GitLab Agent)
- [ ] Automated DNS management (update DNS records)
- [x] Single Sign-On (keycloak)
- [ ] Reasonably secure
  - [ ] Automated certificate management (cert-manager, _Currently: only in development_)
  - [x] Declarative secret management (vault and external-secrets)
  - [x] Replace all default passwords with randomly generated ones
- [x] Only use open-source technologies
- [x] Everything is defined as code
- [ ] Backup solution (3 copies, 2 separate device, 2 separate offsite)
- [ ] Observability
  - [ ] Monitoring
  - [ ] Logging
  - [ ] Alerting
- [x] Core/System applications
  - [x] Kubed
  - [x] OpenEBS
  - [x] Traefik
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
  - [ ] Secrets rotation
  - [x] Self healing
- [x] Minimal dependency on external services
- [ ] Additional applications
  - [x] GitLab (git server and private container registry)
  - [ ] Nextcloud
  - [ ] Vaultwarden

## Unplanned

Nice to have

- [ ] Addition applications
  - [ ] Plex
- [ ] Serverless ([Knative](https://knative.dev/))
