#!/bin/bash

tfi
tfp
terraform state pull

terraform show -json plan > salida
# cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] != "no-op")) | map("\(.change.actions | join(",")) \(.address)") | .[]'

for k in $(cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] == "delete")) | map(.address) | .[]'); do
    if [[ "$k" == *"["* ]]; then
        name=$(echo "$k" | sed 's/.*\["\(.*\)"\].*/\1/')
        name_without_sufix=$(echo "$k" | sed 's/\[.*//')
        echo "terraform state mv -state=.terraform/terraform.tfstate '$k' 'module.apigatewayresource[\"$name\"].$name_without_sufix'"
    else
        echo "terraform state mv -state=.terraform/terraform.tfstate $k \"module.apigatewayresource.$k\""
    fi
done

# updateDynamo $STATE $TF_S3_BUCKET $TF_DYNAMO_TABLE
# aws s3 cp ${STATE}.tfstate s3://$TF_S3_BUCKET/${STATE}.tfstate

# 
# terraform state push

tfi
tfp
terraform refresh

