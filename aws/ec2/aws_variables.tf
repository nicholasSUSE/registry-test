variable "prefix" {
  description = "The prefix to use for all resources"
  type        = string
}

variable "user" {
  description = "The username for the node"
  type        = string
}

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
