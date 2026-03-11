#!/bin/bash

echo "Updating system"

sudo yum update -y

echo "Installing Docker"

sudo yum install docker -y

sudo systemctl start docker
sudo systemctl enable docker

echo "Building Docker Image"

sudo docker build -t devops-lab .

echo "Running Container"

sudo docker run -d -p 80:80 devops-lab