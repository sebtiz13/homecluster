# Deploy app
resource "kubectl_manifest" "traefik" {
  depends_on = [kubectl_manifest.argocd_project]

  yaml_body = file("${local.manifests_folder}/traefik.yaml")
}
resource "null_resource" "traefik_wait" {
  depends_on = [kubectl_manifest.traefik]

  // Etablish SSH connection
  connection {
    type        = "ssh"
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.use_private_key ? file(local.ssh_connection.private_key) : null
    agent       = local.ssh_connection.agent
  }

  provisioner "remote-exec" {
    inline = [
      // Wait for external secrets is start
      "until [ \"$(kubectl get deploy -n traefik traefik -o=jsonpath='{.status.readyReplicas}' 2>/dev/null)\" = \"1\" ]; do sleep 1; done"
    ]
  }
}

# Create middlewares
resource "kubectl_manifest" "traefik_https_redirect" {
  depends_on = [null_resource.traefik_wait]

  yaml_body = yamlencode({
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "redirect-https"
      namespace = "traefik"
    }

    spec = {
      redirectScheme = {
        scheme    = "https"
        permanent = true
      }
    }
  })
}

# Create certificate
# TODO: Support production !
resource "kubectl_manifest" "cert_manager_certificate" {
  depends_on = [null_resource.traefik_wait, null_resource.cert_manager_wait]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = replace(local.base_domain, ".", "-")
      namespace = "traefik"
    }

    spec = {
      issuerRef = {
        name = "selfsigned"
        kind = "ClusterIssuer"
      }

      dnsNames   = [local.base_domain, "*.${local.base_domain}", "console.s3.${local.base_domain}"]
      secretName = local.tls_secret_name
      secretTemplate = {
        annotations = {
          "kubed.appscode.com/sync" = "domain=${local.base_domain}"
        }
        labels = {
          domain = local.base_domain
        }
      }
    }
  })
}
