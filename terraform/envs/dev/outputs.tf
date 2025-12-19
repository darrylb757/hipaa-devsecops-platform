output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  value = module.vpc.db_subnet_ids
}

output "azs" {
  value = module.vpc.azs
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "bastion_instance_id" {
  value = module.bastion.instance_id
}

output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}
