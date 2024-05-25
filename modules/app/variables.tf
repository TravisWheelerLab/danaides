variable "storage_performance_mode" {
  type = string
  description = "The performance mode of the file system. Can be either 'generalPurpose' or 'maxIO'"
  default = "generalPurpose"
}

variable "storage_throughput_mode" {
  type = string
  description = "Throughput mode for the file system. Can be either 'bursting', 'elastic', or 'provisioned'"
  default = "elastic"
}

variable "storage_throughput_in_mibps" {
  type = number
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with 'provisioned' throughput mode"
}

variable "vpc_id" {
  type = string
  description = "The ID of the VPC to create the EFS in"
}

variable "subnet_ids" {
  type = list(string)
  description = "The IDs of the subnets to create the EFS mount targets in"
}
