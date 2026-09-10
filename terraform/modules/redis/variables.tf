variable "name_prefix" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "node_type" { type = string }
variable "engine_version" {
  type    = string
  default = "7.1"
}
variable "num_cache_clusters" {
  type    = number
  default = 2
}
