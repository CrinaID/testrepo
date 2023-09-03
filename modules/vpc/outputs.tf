output "private_subnet_ids" {
    value = var.private_subnets["*"].id
  
  
}
output "public_subnet_ids" {
    value = var.public_subnets["*"].id
}