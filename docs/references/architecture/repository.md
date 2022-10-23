# Repository architecture

## [Applications](/apps/)

The apps values deployed with **ArgoCD**

> This folder have strict structure: `<cluster>/<project>/<app>`

### Available cluster

- `salamandre`
- `baku`

### Available project

- `system`: System cluster critical apps
- `infrastructure`: Infrastructure apps

### Supported files

- `values.yaml`: The **ArgoCD** application informations (chart, version, plugin, cluster and namespace).
- `values.<environment>.yaml`: Overwrite values for specific environment
- `appValues.yaml`: The chart values
- `appValues.<environment>.yaml`: Overwrite charts values for specific environment
- `readme.md`: Description of project (with home page, source and secrets values if required)

> Available `environment`: `vm` (for development) and `production`

## [Charts](/charts/)

The extends apps charts + `common-app` for build [applications](#applications).

## [Manifests](/manifests/)

The builded production manifests for deploy it to cluster with **GitOps**.

> This folder have strict structure: `<cluster>/<app>.yaml`
>
> ⚠️ This folder is managed by CI, so user modification is not required.

## [Documentation](/docs/)

This folder contains all documentation.

## [Provisioning](/terraform/)

Files for provisioning clusters.

> This folder have strict root folders: `baku` (for baku cluster), `salamandre` (for salamandre cluster) and `common-modules`

### Development values

The values for development, is defined in static at `<cluster>/vm.tfvars`.

## [Virtual machines](/vagrant/)

Virtual machine files
