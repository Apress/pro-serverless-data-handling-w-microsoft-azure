$tenantId = "2add9dd5-5aff-40bd-95c5-75bd96f56401"

# Sign into your azure tenant
az login --tenant $tenantId --use-device-code

# Create a resource group
az group create `
  --location "West Europe" `
  --name "ServerlessQueues"

# create the infrastructure from an arm template
az deployment group create `
  --resource-group "ServerlessQueues" `
  --template-file "ARMServerlessQueues.json"



