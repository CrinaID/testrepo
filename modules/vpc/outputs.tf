output "private_subnet_ids" {
    value = var.private_subnets.*.id
}