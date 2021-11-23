tfi
tfp
export STATE=charla5
export TF_S3_BUCKET=charla-tf-state
export TF_DYNAMO_TABLE=charla-tf-state

aws s3 cp s3://${TF_S3_BUCKET}/${STATE}.tfstate .
aws s3 cp s3://${TF_S3_BUCKET}/terraform.tfstate .
terraform show -json plan > salida

for k in $(cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] != "no-op")) | map(.address) | .[]'); do
    echo terraform state mv -state-out=${STATE}.tfstate -state=terraform.tfstate $k $k
done

aws s3 cp ${STATE}.tfstate s3://${TF_S3_BUCKET}/${STATE}.tfstate
aws dynamodb delete-item \
    --table-name ${TF_DYNAMO_TABLE} \
    --key "{\"LockID\": {\"S\": \"${TF_S3_BUCKET}/${STATE}.tfstate-md5\"}}"

tfi
tfp
terraform refresh

