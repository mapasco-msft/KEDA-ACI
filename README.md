# Bursting Jobs with KEDA
This project enables [KEDA](https://github.com/kedacore/keda) to spawn jobs into
Azure Containter Instances 
([ACI](https://azure.microsoft.com/en-us/services/container-instances/)).

# Known Issues
There is a known issue with ACI containers not having access to MSI, more can
be found [here](https://github.com/Azure/azure-sdk-for-python/issues/8557).

# Requirements

* [git](https://git-scm.com/)
* [docker](https://docker.com)
* [docker-compose](https://docs.docker.com/compose/install/)
* [helm](https://helm.sh/)
* [kubernetes](https://kubernetes.io/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
* [aad pod identity](https://github.com/Azure/aad-pod-identity)
* [az-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

# Running

To run the following environment variables should be set first:
```sh
export RESOURCE_GROUP="<resource-group>"
export VNET_NAME="<vnet-name>"
export SP_APP_ID="<service-principal-app/client-id>"
export SP_SECRET="<service-pricipal-secret"
export STORAGE_ACCOUNT="<storage-account-name>"
export ACR="<azure-container-registry-name>"
```

## 1. Deploying the infrastrucuture
In the `/deploy/` directory run:
```sh
$ ./deployinfra.sh
```
This will create the following resources:

1. A Resource Group
2. A VNET
3. A Subnet on said VNET
4. Azure Kubernetes Cluster
5. Enables Virtual Nodes on AKS
6. A Managed Service Identitiy (MSI)
7. A Storage Account 
8. A Queue
9. An Azure Container Registry
10. Assigns roles to Service Principals and Managed Service Identity

***NOTE: Role assignment may take a few minutes to propogate, you may need to 
run this script a couple of times***

## 2. Push the Queue Consumer to the ACR
This builds and pushes the Queue Consumer to the Azure Container Registry

```
$ ./dockerpush.sh
```

## 3. Deploy AAD, KEDA, and Queue consumer to AKS
This will generate kubernetes yamls using `helm template`. This removes the 
requirement of Tiller. To run this:

```sh
$ ./deploytokubernetes
```

## 4. Destroying Kube templates
To destroy all running items on Kubernetes, run:

```sh
$ ./prepareforredeploy.sh
```

Note this may need to be run multiple times as there are some issues with KEDA
crds and deleting. Run this script twice to ensure crds can be patched and 
deleted.

# Queue Consumer
This is a simple python container that processes 1 message from a Queue at a
time. KEDA will spin up 1 instance of the Queue Consumer per queue message. This
should be replaced with a more robust message processor and is only used as a
PoC.

This uses Managed Service Identities to retrieve PaaS resources without any 
secrets.

Two environment variables are required for this to run:
1. `STORAGE_ACCOUNT`, the name of your Azure Storage Account
2. `QUEUE_NAME`, the name of your Azure Queue.

Code can be found [here](./queueconsumer/main.py)

# TODO
1. Refactor [deployinfra.sh](./deploy/deployinfra.sh)
2. Improve documentation
