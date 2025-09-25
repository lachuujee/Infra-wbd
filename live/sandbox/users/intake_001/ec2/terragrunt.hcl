dependency "vpc" { config_path = "../vpc" }   # needs outputs (vpc_id/subnets)
dependencies { paths = ["../keypair","../iam"] }  # ordering only

terraform { source = "../../../../../modules/ec2" }

locals { cfg = read_json(find_in_parent_folders("inputs.json")) }

inputs = {
  enabled       = try(local.cfg.modules.ec2.enabled, true)
  name          = try(local.cfg.modules.ec2.name, "ec2")
  ami_id        = local.cfg.modules.ec2.ami_id
  instance_type = try(local.cfg.modules.ec2.instance_type, "t3.micro")
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnet_id     = dependency.vpc.outputs.private_subnet_ids[0]
}

