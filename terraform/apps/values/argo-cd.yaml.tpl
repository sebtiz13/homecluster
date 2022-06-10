fullnameOverride: "argocd"

dex:
  enabled: false

server:
  # Additional command line arguments to pass to argocd-server
  extraArgs:
    - --insecure

  # Environment variables to pass to argocd-server
  env:
    - name: TZ
      value: Europe/Paris

  ingress:
    enabled: true
    annotations:
      %{if var.has_ssl}
      traefik.ingress.kubernetes.io/router.middlewares: traefik-redirect-https@kubernetescrd
      traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
      %{else}
      traefik.ingress.kubernetes.io/router.entrypoints: web
      %{endif}

    ## Argo Ingress.
    ## Hostnames must be provided if Ingress is enabled.
    ## Secrets must be manually created in the namespace
    hosts:
      - argocd.${var.base_domain}
    paths:
      - /
    pathType: Prefix
    %{if var.has_ssl}
    tls:
      - secretName: ${var.tls_secret_name}
        hosts:
          - argocd.${var.base_domain}
    %{endif}

  ## dedicated ingress for gRPC as documented at
  ## https://argoproj.github.io/argo-cd/operator-manual/ingress/
  ingressGrpc:
    enabled: true
    annotations:
      %{if var.has_ssl}
      traefik.ingress.kubernetes.io/router.middlewares: traefik-redirect-https@kubernetescrd
      traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
      %{else}
      traefik.ingress.kubernetes.io/router.entrypoints: web
      %{endif}

    ## Argo Ingress.
    ## Hostnames must be provided if Ingress is enabled.
    ## Secrets must be manually created in the namespace
    hosts:
      - argocd.${var.base_domain}
    paths:
      - /
    pathType: Prefix
    %{if var.has_ssl}
    tls:
      - secretName: ${var.tls_secret_name}
        hosts:
          - argocd.${var.base_domain}
    %{endif}

  ## ArgoCD config
  ## reference https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/argocd-cm.yaml
  configEnabled: true
  config:
    # Disable admin account when Argo CD are deployed
    admin.enabled: "${var.admin_account}"

    # Argo CD's externally facing base URL (optional). Required when configuring SSO
    url: http%{if var.has_ssl}s%{endif}://argocd.${var.base_domain}

    # Ignore Velero Backup to prevent auto prune
    resource.exclusions: |
      - apiGroups:
          - "velero.io"
        kinds:
          - "Backup"
        clusters:
        - "*"

  # Default projects
  additionalProjects:
    - name: cluster-core-apps
      namespace: argo-cd
      additionalLabels: {}
      additionalAnnotations: {}
      description: core apps of cluster
      sourceRepos:
        - "*"
      destinations:
        - namespace: "*"
          server: ${var.clusters.salamandre}
      clusterResourceWhitelist:
        - group: "*"
          kind: "*"
    - name: cluster-apps
      namespace: argo-cd
      additionalLabels: {}
      additionalAnnotations: {}
      description: apps of cluster
      sourceRepos:
        - "*"
      destinations:
        - namespace: "*"
          server: ${var.clusters.salamandre}
      clusterResourceWhitelist:
        - group: "*"
          kind: "*"
    - name: baku-cluster-apps
      namespace: argo-cd
      additionalLabels: {}
      additionalAnnotations: {}
      description: apps of cluster
      sourceRepos:
        - "*"
      destinations:
        - namespace: "*"
          server: ${var.clusters.baku}
      clusterResourceWhitelist:
        - group: "*"
          kind: "*"

  ## ArgoCD rbac config
  ## reference https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/rbac.md
  rbacConfig:
    ## Define association groups and roles to define permissions
    ## policy.csv is an file containing user-defined RBAC policies and role definitions (optional).
    ## Policy rules are in the form:
    ##   p, subject, resource, action, object, effect
    ## Role definitions and bindings are in the form:
    ##   g, subject, inherited-subject
    ## See https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/rbac.md for additional information.
    policy.csv: |
      g, Admin, role:admin
      g, Operator, role:operator
      p, role:operator, applications, get, */*, allow
      p, role:operator, applications, create, */*, allow
      p, role:operator, applications, update, */*, allow
      p, role:operator, applications, delete, */*, allow
      p, role:operator, applications, sync, */*, allow
      p, role:operator, applications, action/*, */*, allow
      p, role:operator, projects, get, *, allow
      p, role:operator, projects, create, *, allow
      p, role:operator, projects, update, *, allow
      p, role:operator, projects, delete, *, allow
      p, role:operator, repositories, get, *, allow
      p, role:operator, repositories, create, *, allow
      p, role:operator, repositories, update, *, allow
      p, role:operator, repositories, delete, *, allow
      p, role:operator, clusters, update, *, allow

    ## policy.default is the name of the default role which Argo CD will falls back to, when
    ## authorizing API requests (optional). If omitted or empty, users may be still be able to login,
    ## but will see no apps, projects, etc...
    policy.default: role:readonly

  resources:
    requests:
      cpu: 4m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

repoServer:
  # Environment variables to pass to argocd-repo-server
  env:
    - name: TZ
      value: Europe/Paris

  ## Enable Custom Rules for the Repo server's Cluster Role resource
  ## Enable this and set the rules: to whatever custom rules you want for the Cluster Role resource.
  ## Defaults to off
  clusterRoleRules:
    # Enable custom rules for the Repo server's Cluster Role resource
    enabled: true
    # List of custom rules for the Repo server's Cluster Role resource
    rules:
      - apiGroups:
          - authentication.k8s.io
        resources:
          - tokenreviews
        verbs:
          - "*"

  ## Repo server service account
  ## If create is set to true, make sure to uncomment the name and update the rbac section below
  serviceAccount:
    create: true
    name: argocd-repo-server
    # Automount API credentials for the Service Account
    automountServiceAccountToken: true

  resources:
    requests:
      cpu: 4m
      memory: 64Mi
    limits:
      cpu: 2000m
      memory: 1024Mi

configs:
  knownHosts:
    data: |
      bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
      github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
      gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
      gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
      gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
      ssh.dev.azure.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7Hr1oTWqNqOlzGJOfGJ4NakVyIzf1rXYd4d7wo6jBlkLvCA4odBlL0mDUyZ0/QUfTTqeu+tm22gOsv+VrVTMk6vwRU75gY/y9ut5Mb3bR5BV58dKXyq9A9UeB5Cakehn5Zgm6x1mKoVyf+FFn26iYqXJRgzIZZcZ5V6hrE0Qg39kZm4az48o0AUbf6Sp4SLdvnuMa2sVNwHBboS7EJkm57XQPVU3/QpyNLHbWDdzwtrlS+ez30S3AdYhLKEOxAG8weOnyrtLJAUen9mTkol8oII1edf7mWWbWVf0nBmly21+nZcmCTISQBtdcyPaEno7fFQMDD26/s0lfKob4Kw8H
      vs-ssh.visualstudio.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7Hr1oTWqNqOlzGJOfGJ4NakVyIzf1rXYd4d7wo6jBlkLvCA4odBlL0mDUyZ0/QUfTTqeu+tm22gOsv+VrVTMk6vwRU75gY/y9ut5Mb3bR5BV58dKXyq9A9UeB5Cakehn5Zgm6x1mKoVyf+FFn26iYqXJRgzIZZcZ5V6hrE0Qg39kZm4az48o0AUbf6Sp4SLdvnuMa2sVNwHBboS7EJkm57XQPVU3/QpyNLHbWDdzwtrlS+ez30S3AdYhLKEOxAG8weOnyrtLJAUen9mTkol8oII1edf7mWWbWVf0nBmly21+nZcmCTISQBtdcyPaEno7fFQMDD26/s0lfKob4Kw8H

controller:
  resources:
    requests:
      cpu: 40m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

redis:
  resources:
    requests:
      cpu: 4m
      memory: 32Mi
    limits:
      cpu: 200m
      memory: 128Mi
