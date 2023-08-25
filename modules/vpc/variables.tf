variable "cidr_vpc" {
  type = string
  default = "10.1.0.0/16"
}
variable "public_subnets" {}
variable "private_subnets" {}
variable "env_name"{}

  

/*variable "subnet_map" {
  description = "Map for subnets - azs - cidr blocks"
  type        = map(map(string))
  default     = {
    dev = {
      public_one = ""
      public_two = ""
      private_one = ""
      private_two = ""
    }
    test = {
      public_one = ""
      public_two = ""
      public_three = ""
      private_one = ""
      private_two = ""
      private_three =""
    }
  }*/
