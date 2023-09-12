output "private_subnets_ids" {
    value = var.private_subnets.*.id
}