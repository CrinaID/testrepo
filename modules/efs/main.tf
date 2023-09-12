# Creating Amazon EFS File system
resource "aws_efs_file_system" "myfilesystem" {
# Creating the AWS EFS lifecycle policy
# Amazon EFS supports two lifecycle policies. Transition into IA and Transition out of IA
# Transition into IA transition files into the file systems's Infrequent Access storage class
# Transition files out of IA storage
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
# Tagging the EFS File system with its value as Myfilesystem
  tags = {
    Name = "${var.project_code}-efs-${var.env_name}"
  }
}

# Creating the EFS access point for AWS EFS File system
resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.myfilesystem.id
}
# Creating the AWS EFS System policy to transition files into and out of the file system.
resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.myfilesystem.id
# The EFS System Policy allows clients to mount, read and perform 
# write operations on File system 
# The communication of client and EFS is set using aws:secureTransport Option
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "Policy01",
    "Statement": [
        {
            "Sid": "Statement",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.myfilesystem.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientRootAccess",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}
# Creating the AWS EFS Mount point in a specified Subnet 
# AWS EFS Mount point uses File system ID to launch.
resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.myfilesystem.id
  subnet_id      = var.subnet_id
}