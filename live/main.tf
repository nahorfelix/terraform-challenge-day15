# ── Root module provider configurations ──────────────────────────────────────
# The root module defines ALL provider instances.
# Modules receive them via the `providers` map — never define providers inside modules.

provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "replica"
  region = "us-west-2"
}

# ── Module call — wires root providers into the module ────────────────────────
module "multi_region_app" {
  source = "../modules/multi-region-app"

  app_name    = var.app_name
  environment = var.environment

  # The providers map keys must match the configuration_aliases declared
  # in the module's required_providers block exactly.
  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}
