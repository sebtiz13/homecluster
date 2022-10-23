resource "random_uuid" "argocd_oidc_secret" {
}
locals {
  argocd_manifest = yamldecode(file("${var.manifests_folder}/argocd.yaml"))
  argocd_values   = yamldecode(local.argocd_manifest.spec.source.plugin.env.1.value)

  argocd_release_name = local.argocd_manifest.spec.source.plugin.env.0.value
  argocd_namespace    = local.argocd_manifest.spec.destination.namespace
  argocd_host         = replace(local.argocd_values.server.config.url, "https://", "")
}

resource "null_resource" "argocd_deploy_crds" {
  depends_on = [kubernetes_namespace.labeled_namespace]

  provisioner "local-exec" {
    command = format(
      "KUBECONFIG=%s ./scripts/argocd-crds.sh %s %s %s %s %s",
      local.kubeconfig_path,
      local.argocd_manifest.spec.source.repoURL,
      local.argocd_manifest.spec.source.chart,
      local.argocd_manifest.spec.source.targetRevision,
      local.argocd_namespace,
      local.argocd_release_name
    )
  }
}

resource "helm_release" "argocd_deploy" {
  depends_on = [null_resource.argocd_deploy_crds]
  timeout    = 10 * 60 // 10 min

  name       = local.argocd_release_name
  namespace  = local.argocd_namespace
  chart      = local.argocd_manifest.spec.source.chart
  repository = local.argocd_manifest.spec.source.repoURL
  version    = local.argocd_manifest.spec.source.targetRevision

  values = [replace(yamlencode(local.argocd_values), "$$", "$")] # This replace skiped interpretation of '$name'
}

# Create vault keys
module "argocd_vault_secrets" {
  depends_on = [null_resource.vault_restart]
  source     = "./modules/vault"

  ssh = local.ssh_connection
  vault = {
    pod   = local.vault_pod
    token = local.vault_root_token
  }
  secrets = {
    "argocd/oidc" = {
      issuer       = local.oidc_url
      cliClientID  = "argocd-cli"
      clientID     = "argocd"
      clientSecret = sensitive(random_uuid.argocd_oidc_secret.result)
    }
  }
}

# Sync app
resource "kubectl_manifest" "argocd_sync" {
  depends_on = [module.argocd_vault_secrets]

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.argocd_manifest)
}

# Retrieve admin password
data "kubernetes_secret" "argocd_admin_password" {
  depends_on = [helm_release.argocd_deploy]

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = local.argocd_namespace
  }
}
