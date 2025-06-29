terraform {
  backend "s3" {
    bucket         = "tf-state-mycompany"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"  

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id         = var.vpc_id
  subnet_ids     = var.private_subnet_ids

  eks_managed_node_groups = {
    ng1 = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }
}

# Write kubeconfig so Jenkins can run kubectl
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
  }
  triggers   = { always = timestamp() }
  depends_on = [module.eks]
}
