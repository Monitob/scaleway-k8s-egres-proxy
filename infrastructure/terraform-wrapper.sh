#!/bin/bash
set -a  # Automatically export all variables
[ -f .env ] && source .env
set +a
terraform "$@" -var-file=terraform.tfvars.local
