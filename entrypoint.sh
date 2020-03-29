#!/usr/bin/env bash

PROJECT_ID=${1}
VM_SERVER_NAME=app-vm
DB_SERVER_NAME=test1-db
CONTAINER_ENV_FILE=./the-client-webapp/env.txt
CONTAINER_IMAGE=gcr.io/$PROJECT_ID/webapp:2.0

gcloud docker --authorize-only

echo "Create a docker image"
pushd the-client-webapp/
docker build -t $CONTAINER_IMAGE .

echo "Push the image to gcr"
docker push $CONTAINER_IMAGE
popd

echo "Create a VM for web application"

gcloud compute instances create-with-container $VM_SERVER_NAME \
  --image-family cos-dev \
  --image-project cos-cloud \
  --CONTAINER_IMAGE $CONTAINER_IMAGE \
  --CONTAINER_ENV_FILE $CONTAINER_ENV_FILE

echo "The VM server IP address"
VM_SERVER_IP=$(gcloud compute instances list | grep ^$VM_SERVER_NAME | grep -v grep | awk '{print $5}' | grep ^[0-9])
echo $VM_SERVER_IP

echo "Create a MySQL server"
gcloud sql instances create $DB_SERVER_NAME \
  --tier db-n1-standard-1 \
  --region europe-west2 \
  --database-version MYSQL_5_7
  --authorized-networks=$VM_SERVER_IP

echo "Update MySQL server root password" 
gcloud sql users set-password root \
  --host=% \
  --instance $DB_SERVER_NAME \
  --password test

echo "Create a new user in MySQL server"
gcloud sql users create user \
  --instance $DB_SERVER_NAME \
  --password test

echo "Create a new DB in MySQL server"
gcloud sql databases create myDb \
  --instance=$DB_SERVER_NAME \
  --charset=latin1

# gcloud sql connect test1-db \
#   --user=root

echo "The MySql server IP address"
DB_SERVER_IP=$(gcloud sql instances list | grep ^$DB_SERVER_NAME | grep -v grep | awk '{print $5}' | grep ^[0-9])
echo $DB_SERVER_IP

echo "Update MySQL server ip address in VM"
gcloud compute instances update-container $VM_SERVER_NAME \
  --container-env=MYSQL_SERVER=$DB_SERVER_IP
