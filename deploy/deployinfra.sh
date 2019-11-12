# Set these
#RESOURCE_GROUP=""
#VNET_NAME=""
#SP_APP_ID=""
#SP_SECRET=""
#STORAGE_ACCOUNT=""

# Create Resource Group
echo "Creating Resource Group"
az group create --name $RESOURCE_GROUP --location westus

# Create Vnet
echo "Creating VNET"
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name AksSubnet \
    --subnet-prefix 10.240.0.0/16

# Create Subnet
echo "Creating Subnet"
az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name VirtualNodeSubnet \
    --address-prefixes 10.241.0.0/16


# Assign Roles
echo "Assigning SP Roles"
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query id -o tsv)
az role assignment create --assignee $SP_APP_ID --scope $VNET_ID --role Contributor

SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name AksSubnet --query id -o tsv)

# Create AKS
echo "Creating AKS"
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name AksCluster \
    --node-count 1 \
    --network-plugin azure \
    --service-cidr 10.0.0.0/16 \
    --dns-service-ip 10.0.0.10 \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id $SUBNET_ID \
    --service-principal $SP_APP_ID \
    --client-secret $SP_SECRET

# Enable Virtual Nodes
echo "Enabling Virtual Nodes"
az aks enable-addons \
    --resource-group $RESOURCE_GROUP \
    --name AksCluster \
    --addons virtual-node \
    --subnet-name VirtualNodeSubnet


# Create Storage account
echo "Creating a Storage Account"
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP

# Creating Queue
echo "Creating a Queue"
az storage queue create \
    --name queue \
    --auth-mode login \
    --account-name $STORAGE_ACCOUNT

SUBSCRIPTION=$(az account show --query id -o tsv)
QUEUE_ID="/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/queueServices/default/queues/queue"

az identity create --name keda-aks-pod-id --resource-group $RESOURCE_GROUP
read MSI_PID MSI_ID MSI_CID <<< $(az identity show --name keda-aks-pod-id --resource-group $RESOURCE_GROUP --query "[principalId, id, clientId]" -o tsv | tr '\n' ' ')

SA_ID=$(az storage account show --name $STORAGE_ACCOUNT --query id -o tsv)
az role assignment create --assignee $SP_APP_ID --scope $MSI_ID --role "Managed Identity Operator"
az role assignment create --assignee $MSI_PID --scope $SA_ID --role "Storage Account Contributor"
az role assignment create --assignee $MSI_PID --scope $QUEUE_ID --role "Storage Queue Data Contributor"

echo "Authenticating with AKS"
az aks get-credentials --resource-group $RESOURCE_GROUP --name AksCluster --admin

echo "Deploying ACR"
ACR_ID=$(az acr create --resource-group $RESOURCE_GROUP --name $ACR --sku "Basic" --query "id" -o tsv)
az role assignment create --assignee $SP_APP_ID --scope $ACR_ID --role "AcrPull"