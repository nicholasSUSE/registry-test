#----------------------------------------------------------------------------------------------

# AWS - INFRA - Variables
# Tags
variable "user" {
  type = string
  description = "AWS user for specific resources"
}
variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "oci-registry"
}

# AWS Networking
variable "aws_access_key_id" {
  type        = string
  description = "AWS access key used to create infrastructure"
}
variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}
variable "aws_session_token" {
  type        = string
  description = "AWS session token used to create AWS infrastructure"
  default     = ""
}
variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-2"
}
variable "aws_zone" {
  type        = string
  description = "AWS zone used for all resources"
  default     = "us-east-2a"
}
# AWS EC2
variable "instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "t3a.medium"
}
