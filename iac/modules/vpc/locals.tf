locals {
  public_subnet_map = {
    for idx, az in var.availability_zones : az => {
      cidr_block = var.public_subnet_cidrs[idx]
      az         = az
    }
  }

  private_subnet_map = {
    for idx, az in var.availability_zones : az => {
      cidr_block = var.private_subnet_cidrs[idx]
      az         = az
    }
  }
}
