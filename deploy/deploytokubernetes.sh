helm dependency build ../charts/main

OUTPUT_DIR="../charts/generated-yamls"
mkdir $OUTPUT_DIR

helm template \
	--set global.image.repository="$ACR.azurecr.io/" \
	--set global.operatorName="keda-operator" \
	--set aad-pod-identity.identity.id="$MSI_ID" \
	--set aad-pod-identity.identity.clientId="$MSI_CID" \
	--set aad-pod-identity.azureIdentity="keda-aks-pod-id" \
	--set keda.azureaccount.name="$STORAGE_ACCOUNT" \
	--set keda.storage.queue.name="queue" \
	--output-dir $OUTPUT_DIR \
	../charts/main
kubectl apply --recursive --filename $OUTPUT_DIR
# Applying twice due to failure of application order
kubectl apply --recursive --filename $OUTPUT_DIR
rm -rf $OUTPUT_DIR