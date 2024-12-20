variable "access_key" {
  description = "AWS Access Key ID"
  default = ""
}

variable "secret_key" {
  description = "AWS Secret Access Key"
  default = ""
}

variable "hetzner_dns_key" {
  type        = string
  description = "Hetzner API Secret Key"
   default = "0000"
}

variable "enabled_ip_cidrs" {
  description = "List of CIDRs in string format"
  type        = string
  default     = "1.1.1.1,8.8.8.8"
}


locals {
  cidr_blocks = split(",", var.enabled_ip_cidrs)
}

# for RabbitAccounts
variable "RabbitAdm_pwd" {
  type        = string
  description = "password for RabbitAdm"
   default = "!qaz2wsx3edc"
}


variable "RabbitReader_pwd" {
  type        = string
  description = "password for RabbitReader"
   default = "!qaz2wsx3edc"
}

variable "RabbitWriter_pwd" {
  type        = string
  description = "password for RabbitWriter"
   default = "!qaz2wsx3edc"
}