resource "random_uuid" "argocd_oidc_secret" {
}
locals {
  argocd_manifest = yamldecode(file("${var.manifests_folder}/argocd.yaml"))
  argocd_values   = yamldecode(local.argocd_manifest.spec.source.plugin.env.1.value)

  argocd_namespace = local.argocd_manifest.spec.destination.namespace
  argocd_host      = replace(local.argocd_values.server.config.url, "https://", "")
}

resource "helm_release" "argocd_deploy" {
  depends_on = [kubernetes_namespace.labeled_namespace]
  timeout    = 10 * 60 // 10 min

  name       = local.argocd_manifest.spec.source.plugin.env.0.value
  namespace  = local.argocd_namespace
  chart      = local.argocd_manifest.spec.source.chart
  repository = local.argocd_manifest.spec.source.repoURL
  version    = local.argocd_manifest.spec.source.targetRevision

  values = [replace(yamlencode(local.argocd_values), "$$", "$")] # This replace skiped interpretation of '$name'
}

resource "kubectl_manifest" "argocd_projects" {
  for_each   = toset(local.argocd_projects)
  depends_on = [helm_release.argocd_deploy]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"

    metadata = {
      name      = each.key
      namespace = local.argocd_namespace
    }

    spec = {
      description = "${each.key} apps"
      sourceRepos = ["*"]
      destinations = [{
        namespace = "*"
        server    = local.clusters.salamandre
        }, {
        namespace = "*"
        server    = local.clusters.baku
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  })
}

# Create vault keys
resource "null_resource" "vault_argocd_secret" {
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
    content = templatefile("./scripts/vault/argocd.sh", {
      root_tooken = local.vault_root_token

      oidc = {
        url           = local.oidc_url
        cli_client_id = "argocd-cli"
        client_id     = "argocd"
        client_secret = sensitive(random_uuid.argocd_oidc_secret.result)
      }
    })
    destination = "/tmp/vault-argocd.sh"
  }

  // Apply file
  provisioner "remote-exec" {
    inline = [
      "kubectl exec ${local.vault_pod} -- /bin/sh -c \"`cat /tmp/vault-argocd.sh`\" > /dev/null"
    ]
  }
}

# Sync app
resource "kubectl_manifest" "argocd_sync" {
  depends_on = [null_resource.vault_argocd_secret]

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
