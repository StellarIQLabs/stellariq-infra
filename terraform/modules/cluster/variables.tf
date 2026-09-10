variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_types" { type = list(string) }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "desired_size" { type = number }
variable "cluster_version" {
  type    = string
  default = "1.30"
}
