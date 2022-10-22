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
  gitlab_host      = local.gitlab_values.gitlab.global.hosts.gitlab.name
  gitlab_kas_host  = local.gitlab_values.gitlab.global.hosts.kas.name
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
module "gitlab_vault_secrets" {
  depends_on = [null_resource.vault_restart]
  source     = "./modules/vault"

  ssh = local.ssh_connection
  vault = {
    pod   = local.vault_pod
    token = local.vault_root_token
  }
  secrets = {
    "gitlab/database" = {
      host     = "postgresql.loc"
      database = "gitlab"
      user     = "gitlab"
      password = module.gitlab_database.password
    }
    "gitlab/s3" = {
      endpoint  = "http://${local.minio_endpoint}"
      region    = local.minio_region
      accessKey = "gitlab"
      secretKey = sensitive(random_string.gitlab_s3_secret_key.result)
      # Buckets
      bucket_artifacts = "gitlab-artifacts"
      bucket_backups   = "gitlab-backups"
      bucket_depsProxy = "gitlab-dependency-proxy"
      bucket_packages  = "gitlab-packages"
      bucket_pages     = "gitlab-pages"
      bucket_registry  = "gitlab-registry"
      bucket_runner    = "gitlab-runner"
      bucket_tfState   = "gitlab-terraform-state"
      bucket_uploads   = "gitlab-uploads"
      bucket_lfs       = "git-lfs"
    }
    "gitlab/oidc" = {
      issuer       = local.oidc_url
      clientID     = "gitlab"
      clientSecret = sensitive(random_string.gitlab_oidc_secret.result)
    }
    "gitlab/runner" = {
      registrationToken = sensitive(random_string.gitlab_runner_registration_token.result)
    }
  }
}

# Deploy app
resource "kubectl_manifest" "gitlab" {
  depends_on = [kubectl_manifest.minio, module.gitlab_vault_secrets]
  count      = contains(local.excluded_apps, "gitlab") ? 0 : 1

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.gitlab_manifest)
}
