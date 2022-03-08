$tenantId = "2add9dd5-5aff-40bd-95c5-75bd96f56401"
# login to your tenant
az login --tenant $tenantId --use-device-code

az group create `
  --location "West Europe" `
  --name "AzureDataFactoryServerless"


# $suffix = -join ((97..122) | Get-Random -Count 5 | % {[char]$_})
$suffix = "pdvxk" #-join ((97..122) | Get-Random -Count 5 | % {[char]$_})

az datafactory factory create `
  --location "West Europe" `
  --name "adfServerless$suffix" `
  --resource-group "AzureDataFactoryServerless"

az storage account create `
  --name "stgserverless$suffix" `
  --location "West Europe" `
  --resource-group "AzureDataFactoryServerless" `
  --sku Standard_LRS 

$keys = (az storage account keys list `
  --account-name "stgserverless$suffix" `
| ConvertFrom-JSON)

az storage container create `
  --name "source-data" `
  --account-key $keys[0].value `
  --account-name "stgserverless$suffix" 

az storage blob copy start `
  --account-key $keys[0].value `
  --account-name "stgserverless$suffix" `
  --destination-blob "yellow_tripdata_2019-01.csv" `
  --destination-container "source-data" `
  --source-uri https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2019-01.csv

  (az storage blob show `
    --account-key $keys[0].value `
    --account-name "stgserverless$suffix" `
    --name "yellow_tripdata_2019-01.csv" `
    --container "source-data" `
  | ConvertFrom-Json).properties.copy 

az sql server create `
  --name "sqlsrv-adf-$suffix" `
  --resource-group "AzureDataFactoryServerless" `
  --location "West Europe" `
  --admin-user "sqluser" `
  --admin-password "Pa$$w01rd!!"

az sql db create `
  --resource-group "AzureDataFactoryServerless" `
  --server "sqlsrv-adf-$suffix" `
  --name "MySinkDB" `
  --edition GeneralPurpose `
  --family Gen5 `
  --min-capacity 0.5 `
  --capacity 2 `
  --compute-model Serverless `
  --auto-pause-delay 720

$ipaddress = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
az sql server firewall-rule create `
  --resource-group "AzureDataFactoryServerless" `
  --server "sqlsrv-adf-$suffix" `
  --name "My IP Address" `
  --start-ip-address $ipaddress `
  --end-ip-address $ipaddress 

az sql server firewall-rule create `
  --resource-group "AzureDataFactoryServerless" `
  --server "sqlsrv-adf-$suffix" `
  --name "Allow Acces to Azure Resources" `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0