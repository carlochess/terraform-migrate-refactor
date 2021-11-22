tfi
tfp
export STATE=iam
export TF_S3_BUCKET=checkin-terraform
export TF_DYNAMO_TABLE=terraform

aws s3 cp s3://${TF_S3_BUCKET}/${STATE}.tfstate .
aws s3 cp s3://${TF_S3_BUCKET}/terraform.tfstate .
terraform show -json plan > salida
for k in $(cat ./salida | jq -r '.resource_changes | map(select(.change.actions[0] != "no-op")) | map(.address) | .[]'); do
    echo terraform state mv -state-out=${STATE}.tfstate -state=terraform.tfstate $k $k
done

aws s3 --profile checkin cp ${STATE}.tfstate s3://${TF_S3_BUCKET}/${STATE}.tfstate
aws dynamodb --profile checkin delete-item \
    --table-name ${TF_DYNAMO_TABLE} \
    --key "{\"LockID\": {\"S\": \"${TF_S3_BUCKET}/${STATE}.tfstate-md5\"}}"

tfi
tfp
terraform refresh

