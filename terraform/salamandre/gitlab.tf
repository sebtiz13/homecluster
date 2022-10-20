# Generate secrets and passwords
resource "random_password" "gitlab_db_password" {
  length  = 16
  special = false
}
resource "random_string" "gitlab_s3_secret_key" {
  length  = 40
  special = false
}
resource "random_string" "gitlab_runner_registration_token" {
  length  = 64
  special = false
}
resource "random_string" "gitlab_oidc_secret" {
  length  = 32
  special = false
}

# Extract values
locals {
  gitlab_manifest = yamldecode(file("${var.manifests_folder}/gitlab.yaml"))
  gitlab_values   = yamldecode(local.gitlab_manifest.spec.source.plugin.env.1.value)

  gitlab_namespace = local.gitlab_manifest.spec.destination.namespace
  gitlab_host      = local.gitlab_values.global.hosts.gitlab.name
  gitlab_kas_host  = local.gitlab_values.global.hosts.kas.name
}

# Create database access
module "gitlab_database" {
  source     = "./modules/database"
  depends_on = [null_resource.postgresql_install]

  ssh      = local.ssh_connection
  username = "gitlab"
  database = "gitlab"
}

# Create vault keys
resource "null_resource" "vault_gitlab_secret" {
  depends_on = [null_resource.vault_restart]

  // Etablish SSH connection
  connection {
    type        = "ssh"
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.use_private_key ? file(local.ssh_connection.private_key) : null
    agent       = local.ssh_connection.agent
  }

  // Upload files
  provisioner "file" {
    content = templatefile("./scripts/vault/gitlab.sh", {
      root_tooken = local.vault_root_token

      database = {
        database = "gitlab"
        user     = "gitlab"
        password = module.gitlab_database.password
      }
      s3 = {
        endpoint  = "http://${local.minio_endpoint}"
        region    = local.minio_region
        accessKey = "gitlab"
        secretKey = sensitive(random_string.gitlab_s3_secret_key.result)
        buckets = {
          artifacts = "gitlab-artifacts"
          backups   = "gitlab-backups"
          depsProxy = "gitlab-dependency-proxy"
          packages  = "gitlab-packages"
          pages     = "gitlab-pages"
          registry  = "gitlab-registry"
          runner    = "gitlab-runner"
          tfState   = "gitlab-terraform-state"
          uploads   = "gitlab-uploads"
          lfs       = "git-lfs"
        }
      }
      oidc = {
        url          = local.oidc_url
        clientId     = "gitlab"
        clientSecret = sensitive(random_string.gitlab_oidc_secret.result)
      }
      runner = {
        registrationToken = sensitive(random_string.gitlab_runner_registration_token.result)
      }
    })
    destination = "/tmp/vault-gitlab.sh"
  }

  // Apply file
  provisioner "remote-exec" {
    inline = [
      "kubectl exec ${local.vault_pod} -- /bin/sh -c \"`cat /tmp/vault-gitlab.sh`\" > /dev/null"
    ]
  }
}

# Create secrets
resource "kubectl_manifest" "gitlab_credentials" {
  depends_on = [null_resource.vault_gitlab_secret, null_resource.external_secrets_wait]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "gitlab-credentials"
      namespace = local.gitlab_namespace
    }

    spec = {
      secretStoreRef  = local.secretStoreRef
      refreshInterval = "1h"

      target = {
        template = {
          type = "Opaque"
          data = {
            "postgresql-password" = "{{ .password }}"
          }
        }
      }
      dataFrom = [{
        extract = {
          key = "gitlab/database"
        }
      }]
    }
  })
}
resource "kubectl_manifest" "gitlab_storage" {
  depends_on = [null_resource.vault_gitlab_secret, null_resource.external_secrets_wait]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "gitlab-storage"
      namespace = local.gitlab_namespace
    }

    spec = {
      secretStoreRef  = local.secretStoreRef
      refreshInterval = "1h"

      target = {
        template = {
          type = "Opaque"
          data = {
            accesskey  = "{{ .accesskey }}"
            secretkey  = "{{ .secretkey }}"
            connection = file("./values/gitlab/storage.yaml")
          }
        }
      }
      dataFrom = [{
        extract = {
          key = "gitlab/s3"
        }
      }]
    }
  })
}
resource "kubectl_manifest" "gitlab_backup" {
  depends_on = [null_resource.vault_gitlab_secret, null_resource.external_secrets_wait]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "gitlab-backup"
      namespace = local.gitlab_namespace
    }

    spec = {
      secretStoreRef  = local.secretStoreRef
      refreshInterval = "1h"

      target = {
        template = {
          type = "Opaque"
          data = {
            config = file("./values/gitlab/backup.conf")
          }
        }
      }
      dataFrom = [{
        extract = {
          key = "gitlab/s3"
        }
      }]
    }
  })
}
resource "kubectl_manifest" "gitlab_oidc" {
  depends_on = [null_resource.vault_gitlab_secret, null_resource.external_secrets_wait]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "gitlab-oidc"
      namespace = local.gitlab_namespace
    }

    spec = {
      secretStoreRef  = local.secretStoreRef
      refreshInterval = "1h"

      target = {
        template = {
          type = "Opaque"
          data = {
            provider = templatefile("./values/gitlab/oidc.yaml", {
              url = local.gitlab_host
            })
          }
        }
      }
      dataFrom = [{
        extract = {
          key = "gitlab/oidc"
        }
      }]
    }
  })
}

# Deploy app
resource "kubectl_manifest" "gitlab" {
  depends_on = [
    kubectl_manifest.minio,
    kubectl_manifest.gitlab_credentials,
    kubectl_manifest.gitlab_storage,
    kubectl_manifest.gitlab_backup,
    kubectl_manifest.gitlab_oidc
  ]

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.gitlab_manifest)
}
