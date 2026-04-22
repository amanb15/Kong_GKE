provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 2
  deletion_protection      = false

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {}
}

resource "google_container_node_pool" "nodes" {
  name       = "default-pool"
  cluster    = google_container_cluster.cluster.name
  location   = var.zone
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
  }

  depends_on = [google_container_cluster.cluster]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = "https://${google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  load_config_file       = false
}

resource "kubernetes_namespace" "kong" {
  metadata {
    name = var.namespace
  }

  depends_on = [google_container_node_pool.nodes]
}

resource "helm_release" "kong_operator" {
  name       = "kong-operator"
  repository = "https://charts.konghq.com"
  chart      = "kong-operator"
  namespace  = var.namespace

  create_namespace = false
  skip_crds = true

  set {
    name  = "env.ENABLE_CONTROLLER_KONNECT"
    value = "true"
  }
  
  # 🔥 Critical fixes
  wait    = true
  timeout = 600

  depends_on = [kubernetes_namespace.kong]
}

resource "kubernetes_secret" "konnect" {
  metadata {
    name      = "konnect-api-auth-secret"
    namespace = var.namespace
    labels = {
      "konghq.com/credential" = "konnect"
      "konghq.com/secret"     = "true"
    }
  }

  data = {
    token = var.konnect_pat
  }

  type = "Opaque"

  depends_on = [helm_release.kong_operator]
}

resource "kubectl_manifest" "auth_config" {
  yaml_body = <<YAML
apiVersion: konnect.konghq.com/v1alpha1
kind: KonnectAPIAuthConfiguration
metadata:
  name: konnect-api-auth
  namespace: ${var.namespace}
spec:
  type: secretRef
  secretRef:
    name: konnect-api-auth-secret
  serverURL: ${var.konnect_server_url}
YAML

  depends_on = [kubernetes_secret.konnect]
}

resource "kubectl_manifest" "gateway_config" {
  yaml_body = <<YAML
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-configuration
  namespace: ${var.namespace}
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:3.14

  konnect:
    authRef:
      name: konnect-api-auth
    source: Mirror
    mirror:
      konnect:
        id: ${var.konnect_control_plane_id}
YAML

  depends_on = [kubectl_manifest.auth_config]
}

resource "kubectl_manifest" "gateway_class" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-configuration
    namespace: ${var.namespace}
YAML
}

resource "kubectl_manifest" "gateway" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: ${var.namespace}
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    protocol: HTTP
    port: 80
YAML

  depends_on = [kubectl_manifest.gateway_class]
}
