output "private_subnet_one_id" {
    value = aws_subnet.private_subnets[0].id
}

output "private_subnet_two_id" {
    value = aws_subnet.private_subnets[1].id
}
output "public_subnet_one_id" {
    value = aws_subnet.public_subnets[0].id
}
output "public_subnet_two_id" {
    value = aws_subnet.public_subnets[1].id
}