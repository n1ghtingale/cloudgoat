#!/bin/bash

mkdir -p keys
#from cloudgoat2
echo -e 'y\n' | ssh-keygen -b 4096 -t rsa -f ./cloudgoat -q -N ""
chmod 600 ./cloudgoat

if [[ $1 = "" ]]; then
	echo -e "Whitelist IP range required!\n\nAn IP range is required to whitelist access to security groups in the CloudGoat environment.\nThis is done for the safety of your account.\n\nUsage: ./${0##*/} <ip range>\nExample usage: ./${0##*/} 127.0.0.1/24"
	exit 1
fi

allowcidr=$1

mkdir -p ./tmp
printf $allowcidr > ./tmp/allow_cidr.txt

# Bucket names, EC2 password, and Glue previously used this command for random generation: $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
# But Mac systems get the error: "tr: Illegal byte sequence"
cloudgoat_public_bucket_name=$(echo $RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM) # 60 chars max (always under 63 char limit)
cloudgoat_private_bucket_name=$(echo $RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM)
ec2_web_app_password=$(echo $RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM)

if [[ ! -f ./keys/cloudgoat_key ]]; then
  echo "Creating cloudgoat_key for SSH access."
  ssh-keygen -b 2048 -t rsa -f ./keys/cloudgoat_key -q -N ""
  else echo "cloudgoat key found, skipping creation."
fi

if [[ -n `grep insert_cloudgoat_key terraform/ec2.tf` ]]; then
  echo "Inserting cloudgoat_key into Terraform config for EC2 instance."
  awk 'BEGIN{getline k < "keys/cloudgoat_key.pub"}/insert_cloudgoat_key/{gsub("insert_cloudgoat_key",k)}1' terraform/ec2.tf > ./temp && mv ./temp terraform/ec2.tf
  else echo "Public key found in Terraform config, using the existing key."
fi

if [[ -z `gpg --list-keys | grep CloudGoat` ]]; then
  echo "Creating PGP key for CloudGoat use."
  cd keys && gpg --batch --gen-key pgp_options && cd ..
  else echo "CloudGoat PGP key found, using the existing key."
fi

if [[ -f ./keys/pgp_cloudgoat ]]; then
  echo "Base64 PGP public key conversion file found."
  else echo "Creating base64 PGP public key conversion for Terraform use."
  gpg --export CloudGoat | base64 >> keys/pgp_cloudgoat
fi


cd terraform
cgid=$RANDOM
echo -n $cgid > cgid.txt
terraform init
terraform plan -var cloudgoat_private_bucket_name=$cloudgoat_private_bucket_name -var ec2_web_app_password=$ec2_web_app_password -var cloudgoat_public_bucket_name=$cloudgoat_public_bucket_name -var ec2_public_key="$(< ../keys/cloudgoat_key.pub)" -var cgid=$(cat cgid.txt) -out plan.tfout
terraform apply -auto-approve plan.tfout

terraform destroy -auto-approve -var cgid=$(cat cgid.txt) -target aws_cloudformation_stack.test_lamp_stack_deleted

cd .. && ./extract_creds.py


## Uncomment the following lines to enable the Glue development endpoint (along with kill.sh, extract_creds.py, and ./terraform/glue.tf)
#glue_dev_endpoint_name=$(echo $RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM)
#printf $glue_dev_endpoint_name > ./tmp/glue_dev_endpoint_name.txt
#aws glue create-dev-endpoint --endpoint-name "$glue_dev_endpoint_name" --role-arn "$(< tmp/glue_role_arn.txt)" --public-keys "$(< keys/cloudgoat_key.pub)" --number-of-nodes 2 --region us-west-2 1>/dev/null
#echo "Created Glue development: $glue_dev_endpoint_name, unless an error is shown above. It should be in the 'PROVISIONING' state currently, use the following AWS CLI command to fetch the public endpoint once it is successfully launched: 'aws glue get-dev-endpoint --region us-west-2 --endpoint-name $glue_dev_endpoint_name', then you can SSH into the 'glue' user if you are using this as a starting point."
