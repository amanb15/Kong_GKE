variable "project_id" {
  type = string
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "cluster_name" {
  default = "kong-gke-gcp-project"
}

variable "node_count" {
  default = 1
}

variable "machine_type" {
  default = "e2-medium"
}

variable "namespace" {
  default = "kong"
}

variable "konnect_pat" {
  type      = string
  sensitive = true
}

variable "konnect_control_plane_id" {
  type = string
}

variable "konnect_server_url" {
  default = "https://us.api.konghq.com"
}
