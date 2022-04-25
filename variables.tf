variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "name" {
  description = "name"
}

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}





/*
variable "project" {
  type = string
}

variable "name_com_token" {
  type = string
}

variable "name_com_username" {
  type = string
}

variable "domain_name" {
  type = string
}
*/