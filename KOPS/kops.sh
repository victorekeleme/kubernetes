#!/bin/bash

<<COMMENT
# Input variable
echo "Enter REGION e.g us-east-2"
read REGION

echo "Enter NETWORK e.g weave"
read NETWORK

echo "Enter MASTER_SIZE e.g t2.medium"
read MASTER_SIZE

echo "Enter MASTER_COUNT e.g 1-100"
read MASTER_COUNT

echo "Enter WORKER_SIZE e.g t2.medium"
read WORKER_SIZE

echo "Enter WORKER_COUNT e.g 1-100"
read WORKER_COUNT
COMMENT

REGION="us-east-2"
NETWORK="weave"
MASTER_SIZE="t2.medium"
MASTER_COUNT=1
WORKER_SIZE="t2.medium"
WORKER_COUNT=1
BUCKET_NAME="vistein"
PROVIDER="aws"



# Create KOPS cluster
kops create cluster --zones $REGION --networking $NETWORK --master-size $MASTER_SIZE --master-count $MASTER_COUNT --node-size $WORKER_COUNT --node-count $WORKER_COUNT --cloud $PROVIDER $NAME


#Checking if kops is installed
if [ $? -ne 0 ]
then
        # Creating KOPS user & switching to KOPS User
        sudo adduser kops
        sudo echo "kops  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/kops

        # Installing KOPS on KOPS User
        sudo apt install wget -y
        sudo wget https://github.com/kubernetes/kops/releases/download/v1.22.0/kops-linux-amd64
        sudo chmod +x kops-linux-amd64
        sudo mv kops-linux-amd64 /usr/local/bin/kops

        #Checking if aws cli is installed
        `aws`

        if [ $? -ne 0 ]
        then
                sudo apt install awscli -y
                if [ $? -ne 0 ]
                then
                        sudo apt update -y
                        sudo apt install unzip wget -y
                        sudo curl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o awscli-bundle.zip
                        sudo apt install unzip python -y
                        sudo unzip awscli-bundle.zip
                        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
                else
                        echo "Aws cli installed using: sudo apt install awscli -y"
                fi
        else
                echo "AWS cli is already installed"
        fi

        # Checking if aws cli has the required permissions
        aws s3 ls

        if [ $? -ne 0 ]
        then
                echo "Please Create an IAM role from AWS console or CLI with the below Policies"
                echo
                echo "AmazonEC2FullAccess"
                echo "AmazonS3FullAccess"
                echo "IAMFullAccess"
                echo "AmazonVPCFullAccess"
                echo "AdministratorAccess"
                echo
                echo "Attach IAM role to current KOPS Server Instance and, re-run script "
                echo
                echo "Exiting Script, bye"
                echo
                exit 1
        else
                echo "Correct IAM Permission Attached"
        fi

        # Creating An S3 bucket
        COUNT=0

        `aws s3 mb s3://BUCKET_NAME`

        while [ $? -ne 0 ];
        do
                echo "$BUCKET_NAME has been taken"
                (( COUNT++ ))
                NEW_BUCKET_NAME=$BUCKET_NAME'-'$COUNT

                `aws s3 mb s3://$NEW_BUCKET_NAME`

                if [ $? -eq 0 ]
                then
                    break
                else
                    continue
                fi

        done

        echo " " >> ~/.bashrc
        echo "export NAME=$NEW_BUCKET_NAME.k8s.local" >> ~/.bashrc
        echo "export KOPS_STATE_STORE=s3://$NEW_BUCKET_NAME" >> ~/.bashrc

        source .bashrc

        ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""

        sleep 3

        # Create KOPS cluster
        kops create cluster --zones $REGION --networking $NETWORK --master-size $MASTER_SIZE --master-count $MASTER_COUNT --node-size $WORKER_COUNT --node-count $WORKER_COUNT --cloud $PROVIDER $NAME

        #kops create cluster --zones us-east-2a --networking weave --master-size t2.medium --master-count 1 --node-size t2.medium --node-count 1  vistein-1.k8s.local

        # copy the sshkey into your cluster to be able to access your kubernetes node from the kops server
        kops create secret --name $NAME sshpublickey admin -i ~/.ssh/id_rsa.pub

        #Initialise your kops kubernetes cluser
        kops update cluster $NAME --yes


        #Export the kubeconfig file to manage your kubernetes cluster from a remote server.
        kops export kubecfg --admin $NAME

        #Validate your cluster
        

        while true
        do
                echo "Validating..."
                kops validate cluster
                if [ $? -eq 0 ]
                then
                        break
                else
                        continue
                fi
        done

else
    echo "KOPS Server updated"
fi