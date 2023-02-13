#!/bin/bash
# Creating An S3 bucket

BUCKET_NAME="class30"
COUNT=1

aws s3 mb s3://$BUCKET_NAME

# while true
# do

#     NEW_BUCKET_NAME=$BUCKET_NAME'-'$COUNT
#     (( COUNT++ ))

#     aws s3 rb s3://$NEW_BUCKET_NAME
#     echo "$NEW_BUCKET_NAME Deleted"
# done

while [ $? -ne 0 ]
do
        
        echo "$BUCKET_NAME has been taken"
        (( COUNT++ ))
        NEW_BUCKET_NAME=$BUCKET_NAME'-'$COUNT
        echo "$NEW_BUCKET_NAME"

        aws s3 mb s3://$NEW_BUCKET_NAME

        if [ $? -eq 0 ]
        then
            break
        else
            continue
        fi

done
