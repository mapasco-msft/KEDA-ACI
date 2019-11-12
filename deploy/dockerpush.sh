#!/bin/bash

docker build -t queueconsumer ../queueconsumer
docker tag queueconsumer "$ACR.azurecr.io/queueconsumer:latest"

az acr login $ACR

docker push "$ACR.azurecr.io/queueconsumer:latest"