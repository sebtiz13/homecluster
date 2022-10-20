locals {
  traefik_namespace = "traefik"
}

# Deploy app
resource "kubectl_manifest" "traefik" {
  depends_on = [kubectl_manifest.argocd_projects]

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/traefik.yaml")
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
      namespace = local.traefik_namespace
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
locals {
  certificate_name = replace(var.domain, ".", "-")
}

# TODO: Support production !
resource "kubectl_manifest" "cert_manager_issuer" {
  depends_on = [kubernetes_secret.vm_ca, null_resource.cert_manager_wait]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = {
      name      = "${local.certificate_name}-issuer"
      namespace = local.traefik_namespace
    }

    spec = {
      ca = {
        secretName = kubernetes_secret.vm_ca[0].metadata[0].name
      }
    }
  })
}

resource "kubectl_manifest" "cert_manager_certificate" {
  depends_on = [null_resource.traefik_wait, null_resource.cert_manager_wait]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = local.certificate_name
      namespace = local.traefik_namespace
    }

    spec = {
      issuerRef = {
        name = "${local.certificate_name}-issuer"
        kind = "Issuer"
      }

      dnsNames   = [var.domain, "*.${var.domain}", "console.s3.${var.domain}"]
      secretName = "${local.certificate_name}-tls"
      secretTemplate = {
        annotations = {
          "kubed.appscode.com/sync" = "domain=${var.domain}"
        }
        labels = {
          domain = var.domain
        }
      }
    }
  })
}
