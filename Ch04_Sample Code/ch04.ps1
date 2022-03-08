$tenantId = "2add9dd5-5aff-40bd-95c5-75bd96f56401"
# login to your tenant
az login --tenant $tenantId --use-device-code


az group create `
  --location "West Europe" `
  --name "AzureFunctionsServerless"


$suffix = -join ((97..122) | Get-Random -Count 5 | % {[char]$_})

az storage account create `
  --name "stgserverlessfunc$suffix" `
  --location "West Europe" `
  --resource-group "AzureFunctionsServerless" `
  --sku Standard_LRS 
