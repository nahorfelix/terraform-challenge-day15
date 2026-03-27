terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # Declare the provider aliases this module expects to receive from its caller.
      # The module itself defines NO provider blocks — providers are passed in externally.
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}
