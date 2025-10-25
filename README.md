# Home cluster

**[Features](#features) • [Get started](#get-started) • [Documentation](./docs/) • [Roadmap](./docs/references/roadmap.md)**

This project utilizes [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) and
[GitOps](https://www.weave.works/technologies/gitops/) to automate provisioning, operating, and updating self-hosted
services in our home cluster.

## Overview

> Project status: **BETA**

### Features

- [x] Automated bare metal provisioning with Ansible
- [x] Automated Kubernetes installation and management
- [x] Installing and managing applications using GitOps
- [x] Automatically update apps (with approval)
- [x] Modular architecture, easy to add or remove features/components
- [x] Automated certificate management
- [x] Automatically update DNS records for exposed services
- [x] CI/CD platform
- [x] Git server
- [x] Private container registry
- [x] Support multiple environments (development and production)
- [x] Monitoring and alerting
- [x] Automated offsite backups
- [x] Single sign-on

## Tech stack

<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD045 -->

| Logo                                                                                                                                    | Name                                                 | Description                                                                                                 |
| --------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| <img width="32" src="https://raw.githubusercontent.com/ansible/logos/refs/heads/main/community-marks/Ansible-Community-Mark-Black.svg"> | [Ansible](https://docs.ansible.com/)                 | Provisioning machines                                                                                       |
| <img width="32" src="https://fluxcd.io/favicons/favicon-32x32.png">                                                                     | [Flux](https://fluxcd.io/)                           | Flux is a set of continuous and progressive delivery solutions for Kubernetes that are open and extensible. |
| <img width="32" src="https://raw.githubusercontent.com/jetstack/cert-manager/master/logo/logo.png">                                     | [cert-manager](https://cert-manager.io)              | Cloud native certificate management                                                                         |
| <img width="32" src="https://raw.githubusercontent.com/external-secrets/external-secrets/main/assets/eso-round-logo.svg">               | [External Secrets](https://external-secrets.io/main) | Kubernetes operator that integrates external secret management systems                                      |
| <img width="32" src="https://forgejo.org/favicon.svg">                                                                                  | [Forgejo](https://forgejo.org/)                      | Self-hosted DevOps Platform                                                                                 |
| <img width="32" src="https://helm.sh/img/helm.svg">                                                                                     | [Helm](https://helm.sh)                              | The package manager for Kubernetes                                                                          |
| <img width="32" src="https://avatars.githubusercontent.com/u/49319725?s=32">                                                            | [K3s](https://k3s.io)                                | Lightweight distribution of Kubernetes                                                                      |
| <img height="32" src="https://zitadel.com/icons/favicon-32x32.png">                                                                     | [Zitadel](https://zitadel.com/)                      | Identity and Access Management                                                                              |
| <img width="32" src="https://min.io/resources/img/logo/MINIO_Bird.png">                                                                 | [MinIO](https://min.io/)                             | Multi-Cloud Object Storage                                                                                  |
| <img width="32" src="https://openebs.io/favicon-32x32.png">                                                                             | [OpenEBS (zfs-localpv)](https://openebs.io/)         | CSI driver for provisioning Local PVs backed by ZFS                                                         |
| <img width="32" src="https://www.postgresql.org/media/img/about/press/elephant.png">                                                    | [PostgreSQL](https://www.postgresql.org/)            | Object-relational database                                                                                  |
| <img width="32" src="https://raw.githubusercontent.com/traefik/traefik/master/docs/content/assets/img/traefik.logo.png">                | [Traefik proxy](https://doc.traefik.io/traefik/)     | Kubernetes Ingress Controller                                                                               |
| <img width="32" src="https://www.datocms-assets.com/2885/1676497447-vault-favicon-color.png?h=32&w=32">                                 | [Vault](https://www.vaultproject.io)                 | Secrets and encryption management system                                                                    |
| <img width="32" src="https://victoriametrics.com/icons/favicon-32x32.webp">                                                             | [Vicoria Metrics](https://victoriametrics.com/)      | Monitoring system (like prometheus)                                                                         |
| <img width="32" src="https://grafana.com/static/assets/img/fav32.png">                                                                  | [Grafana](https://grafana.com/)                      | Graph dashboard for monitoring                                                                              |

<!-- markdownlint-restore -->

## Get started

- [Try it out locally](./docs/install/development-sandbox.md) without any hardware
- [Deploy to real hardware](./docs/production/) for production workload

## Roadmap

See [roadmap](./docs/references/roadmap.md) for a list of proposed features.
