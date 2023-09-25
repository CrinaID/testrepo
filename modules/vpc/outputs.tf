output "private_subnets_output" {
    value = aws_subnet.private_subnets
}
output "public_subnets_output" {
    value = aws_subnet.public_subnets
}

output "vpc" {
    value = aws_vpc.vpc_dm_eks
}