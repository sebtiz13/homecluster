# Home cluster

**[Features](#features) • [Get started](#get-started) • [Documentation](./docs/) • [Roadmap](./docs/references/roadmap.md)**

This project utilizes [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) and
[GitOps](https://www.weave.works/technologies/gitops/) to automate provisioning, operating, and updating self-hosted
services in our homelab. It can be used as a highly customizable framework to build your own homelab.

## Overview

> Project status: **BETA**

### Repository architecture

- [apps](./apps/): The apps values deployed with **ArgoCD**
- [charts](./charts/): The extends apps charts + `common-app` for build [apps](./apps/).
- [manifests](./manifests/): The builded production manifests for deploy it to cluster with **GitOps**
- [docs](./docs/): The documentation
- [terraform](./terraform/): Files for provisioning clusters
- [vagrant](./vagrant/): Virtual machine files

### Features

- [x] Automated bare metal provisioning with Terraform
- [x] Automated Kubernetes installation and management
- [ ] Installing and managing applications using GitOps
- [ ] Automatic rolling upgrade for OS and Kubernetes
- [ ] Automatically update apps (with approval, _Currently: only manual update_) 🚧
- [x] Modular architecture, easy to add or remove features/components
- [ ] Automated certificate management (_Currently: only for development_) 🚧
- [ ] Automatically update DNS records for exposed services
- [x] CI/CD platform
- [x] Git server
- [x] Private container registry
- [x] Support multiple environments (dev, prod)
- [ ] Monitoring and alerting
- [ ] Automated offsite backups
- [x] Single sign-on

## Tech stack

<!-- markdownlint-disable MD033 -->

| Logo                                                                                                                      | Name                                                          | Description                                                               |
| ------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------- |
| <img width="32" src="https://cncf-branding.netlify.app/img/projects/argo/icon/color/argo-icon-color.svg">                 | [ArgoCD](https://argoproj.github.io/cd)                       | GitOps tool built to deploy applications to Kubernetes                    |
| <img width="32" src="https://github.com/jetstack/cert-manager/raw/master/logo/logo.png">                                  | [cert-manager](https://cert-manager.io)                       | Cloud native certificate management                                       |
| <img width="32" src="https://appscode.com/assets/images/products/kubed/icons/favicon-32x32.png">                          | [Config Syncer (kubed)](https://appscode.com/products/kubed/) | Synchronize `ConfigMaps` and `Secrets` across namespaces and/or clusters. |
| <img width="32" src="https://raw.githubusercontent.com/external-secrets/external-secrets/main/assets/eso-round-logo.svg"> | [External Secrets](https://external-secrets.io/main)          | Kubernetes operator that integrates external secret management systems    |
| <img width="32" src="https://about.gitlab.com/nuxt-images/ico/favicon-32x32.png?">                                        | [GitLab](https://gitlab.com/)                                 | Self-hosted DevOps Platform                                               |
| <img width="32" src="https://cncf-branding.netlify.app/img/projects/helm/icon/color/helm-icon-color.svg">                 | [Helm](https://helm.sh)                                       | The package manager for Kubernetes                                        |
| <img width="32" src="https://cncf-branding.netlify.app/img/projects/k3s/icon/color/k3s-icon-color.svg">                   | [K3s](https://k3s.io)                                         | Lightweight distribution of Kubernetes                                    |
| <img width="32" src="https://www.keycloak.org/resources/images/keycloak_icon_512px.svg">                                  | [Keycloak](https://www.keycloak.org/)                         | Identity and Access Management                                            |
| <img width="32" src="https://min.io/resources/img/logo/MINIO_Bird.png">                                                   | [MinIO](https://min.io/)                                      | Multi-Cloud Object Storage                                                |
| <img width="32" src="https://cncf-branding.netlify.app/img/projects/openebs/icon/color/openebs-icon-color.svg">           | [OpenEBS (zfs-localpv)](https://openebs.io/)                  | CSI driver for provisioning Local PVs backed by ZFS                       |
| <img width="32" src="https://www.postgresql.org/media/img/about/press/elephant.png">                                      | [PostgreSQL](https://www.postgresql.org/)                     | Object-relational database                                                |
| <img width="32" src="https://www.datocms-assets.com/2885/1620155116-brandhcterraformverticalcolor.svg">                   | [Terraform](https://www.terraform.io/)                        | Automate Infrastructure as code                                           |
| <img width="32" src="https://doc.traefik.io/traefik/assets/img/traefikproxy-vertical-logo-color.svg">                     | [Traefik proxy](https://doc.traefik.io/traefik/)              | Kubernetes Ingress Controller                                             |
| <img width="32" src="https://simpleicons.org/icons/vault.svg">                                                            | [Vault](https://www.vaultproject.io)                          | Secrets and encryption management system                                  |

<!-- markdownlint-restore -->

## Get started

- [Try it out locally](./docs/development-sandbox.md) without any hardware
- [Deploy to real hardware](./docs/production/) for production workload

## Roadmap

See [roadmap](./docs/references/roadmap.md) for a list of proposed features.
