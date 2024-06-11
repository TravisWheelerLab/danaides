module "base-network" {
  source = "./modules/network"

  cidr_block = "192.168.0.0/16"

  vpc_additional_tags = {
    vpc_tag1 = "tag1",
    vpc_tag2 = "tag2",
  }

  public_subnets = {
    first_public_subnet = {
      availability_zone = "us-west-2a"
      cidr_block        = "192.168.0.0/19"
    }
    second_public_subnet = {
      availability_zone = "us-west-2b"
      cidr_block        = "192.168.32.0/19"
    }
  }

  public_subnets_additional_tags = {
    public_subnet_tag1 = "tag1",
    public_subnet_tag2 = "tag2",
  }

  private_subnets = {
    first_private_subnet = {
      availability_zone = "us-west-2a"
      cidr_block        = "192.168.128.0/19"
    }
    second_private_subnet = {
      availability_zone = "us-west-2b"
      cidr_block        = "192.168.160.0/19"
    }
  }

  private_subnets_additional_tags = {
    private_subnet_tag1 = "tag1",
    private_subnet_tag2 = "tag2",
  }
}

module "app" {
  source = "./modules/app"

  storage_performance_mode    = "generalPurpose"
  storage_throughput_mode     = "elastic"
  storage_throughput_in_mibps = 0
  vpc_id                      = module.base-network.vpc_id
  # TODO: can I consoilidate subnet_ids and cidr_blocks into a single variable?
  #       Any disparity between the two lists could cause issues
  subnet_ids         = [for subnet in module.base-network.private_subnets : subnet.id]
  cidr_blocks        = [for subnet in module.base-network.private_subnets : subnet.cidr_block]
  efs_lambda_timeout = 90
}

module "bastion" {
  source = "./modules/bastion"

  vpc_id            = module.base-network.vpc_id
  public_subnet_id  = module.base-network.public_subnets.first_public_subnet.id
  private_subnet_id = module.base-network.private_subnets.first_private_subnet.id
  private_key       = "${path.module}/.bastion_key"
  public_key        = "${path.module}/.bastion_key.pub"
  efs_dns_name      = module.app.efs_dns_name
}
