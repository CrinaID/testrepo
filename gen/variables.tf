variable "region" {
    value = "eu-north-1"
}
variable "devops_policy_name" {
  type    = string
  default = "devops-policy"
}

variable "devops_role_name" {
  type    = string
  default = "dm-gen-devops-role"
}
variable "developer_policy_name" {
  type    = string
  default = "developer-policy"
}

variable "developer_role_name" {
  type    = string
  default = "dm-gen-developer-role"
}

variable "readonly_policy_name" {
  type    = string
  default = "readonly-policy"
}

variable "readonly_role_name" {
  type    = string
  default = "dm-gen-readonly-role"
}