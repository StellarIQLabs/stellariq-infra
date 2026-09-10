variable "name_prefix" { type = string }
variable "db_identifier" { type = string }
variable "retention_days" {
  type    = number
  default = 30
}
