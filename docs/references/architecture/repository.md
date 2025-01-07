# Repository architecture

## [Cluster](/kubernetetes/)

### Available cluster

- `salamandre`
- `baku`

### Available project

- `base`: Reserved folder for **Flux**
- `config`: Public global configuration
- `charts`: Manage charts repositories
- `crds`: Manage applications CRDs
- `core`: Core applications (required for other apps)
- `services`: Applications doesn't depend on each other

## [Documentation](/docs/)

This folder contains all documentation.

## [Provisioning](/ansible/)

Files for provisioning clusters.
