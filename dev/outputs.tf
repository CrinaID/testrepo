output "private_subnet_ids" {
  value = module.vpcmodule.aws_subnet.private_subnets["*"].id
}
output "public_subnet_ids" {
  value = module.vpcmodule.aws_subnet.public_subnets["*"].id
}