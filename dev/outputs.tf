output "private_subnet_ids" {
  value = module.vpcmodule.private_subnets["*"].id
}
output "public_subnet_ids" {
  value = module.vpcmodule.public_subnets["*"].id
}