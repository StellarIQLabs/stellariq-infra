variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage" { type = number }
variable "engine_version" {
  type    = string
  default = "16.3"
}
variable "database_name" {
  type    = string
  default = "stellariq"
}
variable "master_username" {
  type    = string
  default = "stellariq"
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "multi_az" {
  type    = bool
  default = true
}
