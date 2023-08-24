output "publicsubnets"{
    description = "ids of public subnets"
    value = values(aws_subnet.public_subnets)[*].id
} 