function updateDynamo(){
    export STATE=$1
    export TF_S3_BUCKET=$2
    export TF_DYNAMO_TABLE=$2
    cat <<EOF > key.json
    {
        "LockID": {"S": "${TF_S3_BUCKET}/${STATE}.tfstate-md5"}
    }
EOF
 
    cat <<EOF > expression-attribute-names.json
    {
        "#Y":"Digest"
    }
EOF
 
    cat <<EOF > expression-attribute-values.json
    {
        ":y":{"S": "$(md5 -r ${STATE}.tfstate | awk '{print $1}')"}
    }
EOF
# md5 -r terraform.tfstate in mac
# md5sum terraform.tfstate in linux
    aws dynamodb --region us-east-1 update-item --table-name $TF_DYNAMO_TABLE \
       --key file://key.json \
       --update-expression "SET #Y = :y" \
       --expression-attribute-names file://expression-attribute-names.json \
       --expression-attribute-values file://expression-attribute-values.json
}

export STATE=charla4
# export SUB=b2b
# export STATE="charla4${SUB}"
export TF_S3_BUCKET=charla-tf-state
export TF_DYNAMO_TABLE=charla-tf-state

aws s3 cp s3://${TF_S3_BUCKET}/${STATE}.tfstate terraform.tfstate

tfi
tfp
# terraform state pull

terraform show -json plan > salida
# cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] != "no-op")) | map("\(.change.actions | join(",")) \(.address)") | .[]'
aws s3 cp s3://${TF_S3_BUCKET}/${STATE}.tfstate terraform.tfstate

for k in $(cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] != "no-op")) | map(.address) | .[]'); do
    if [[ "$k" == *"["* ]]; then
        name=$(echo "$k" | sed 's/.*\["\(.*\)"\].*/\1/')
        name_without_sufix=$(echo "$k" | sed 's/\[.*\]//')
        if [[ "$name" == "$SUB" ]]; then
            echo "terraform state mv -state=terraform.tfstate '$k' '$name_without_sufix'"
        fi
    fi
done

for k in $(cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] == "delete")) | map(.address) | .[]'); do
    echo "terraform state rm -state=./terraform.tfstate '$k'"
done

mv terraform.tfstate ${STATE}.tfstate
updateDynamo $STATE $TF_S3_BUCKET $TF_DYNAMO_TABLE
aws s3 cp ${STATE}.tfstate s3://$TF_S3_BUCKET/${STATE}.tfstate

tfi
tfp
terraform refresh

