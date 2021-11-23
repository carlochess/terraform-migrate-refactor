
function updateDynamo(){
    export STATE=$1
    export TF_S3_BUCKET=$2
    export TF_DYNAMO_TABLE=$3
    export WORKSPACE_NAME=$4
    cat <<EOF > key.json
    {
        "LockID": {"S": "${TF_S3_BUCKET}/env:/${WORKSPACE_NAME}/${STATE}.tfstate-md5"}
    }
EOF
 
    cat <<EOF > expression-attribute-names.json
    {
        "#Y":"Digest"
    }
EOF
 
    cat <<EOF > expression-attribute-values.json
    {
        ":y":{"S": "$(md5sum terraform.tfstate | awk '{print $1}')"}
    }
EOF
      aws dynamodb update-item
               --table-name ${TF_DYNAMO_TABLE}
               --key file://key.json
               --update-expression "SET #Y = :y"
               --expression-attribute-names file://expression-attribute-names.json
               --expression-attribute-values file://expression-attribute-values.json 
               --return-values ALL_NEW
               --return-consumed-capacity TOTAL
               --return-item-collection-metrics SIZE;
}

terraform workspace list
# terraform workspace select ${PROJECT_ENVIRONMENT} || terraform workspace new ${PROJECT_ENVIRONMENT}
export STATE=charla6
export WORKSPACE_NAME=$(terraform workspace get)
# export SUB=b2b
# export STATE="charla4${SUB}"
export TF_S3_BUCKET=charla-tf-state
export TF_DYNAMO_TABLE=charla-tf-state

tfi
aws s3 cp s3://$TF_S3_BUCKET/${STATE}.tfstate terraform.tfstate

export STATE="env:/${TF_S3_BUCKET}/${STATE}"
echo $STATE
echo aws s3 cp terraform.tfstate "s3://$TF_S3_BUCKET/${STATE}.tfstate"
aws s3 cp terraform.tfstate "s3://$TF_S3_BUCKET/${STATE}.tfstate"
updateDynamo
tfp

terraform state rm $(cat state | grep -v $PROJECT_ENVIRONMENT)
tfp

aws s3 cp "s3://$TF_S3_BUCKET/${STATE}.tfstate" terraform.tfstate 


cat <<EOF > main.py
import json
import os

environment=os.environ['PROJECT_ENVIRONMENT']
with open('dest_state') as fp:
    for cnt, line in enumerate(fp):
        e = line.strip().split(".")
        e[1] = e[1]+"_{}".format(environment)
        print("terraform state mv -state terraform.tfstate "+".".join(e)+" "+line)
EOF

eval "$(python main.py)"

aws s3 cp terraform.tfstate "s3://$TF_S3_BUCKET/${STATE}.tfstate"
updateDynamo
plan

cat <<EOF > main2.py
import json
import os

environment=os.environ['PROJECT_ENVIRONMENT']
with open('dest_state') as fp:
    for cnt, line in enumerate(fp):
        e = line.strip().split(".")
        b = e[1].split("_")
        b[-1] = environment+"_"+b[-1]
        e[1] = "_".join(b)
        print("terraform state mv  -state terraform.tfstate "+".".join(e)+" "+line)
EOF

eval "$(python main2.py)"

terraform workspace list
terraform workspace select dev
terraform workspace select qa
terraform workspace select uat
terraform workspace select staging
terraform workspace select prod

