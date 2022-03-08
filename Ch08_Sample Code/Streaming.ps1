$tenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# An Ihrem Tenant anmelden
az login --tenant $tenantId --use-device-code

az group create `
  --location "West Europe" `
  --name "ServerlessStreamingIoT"

az extension add --name azure-iot

az iot hub create `
  --name "IoTHubServerless" `
  --resource-group "ServerlessStreamingIoT" `
  --partition-count 2 `
  --sku F1

az iot hub device-identity create `
  --hub-name "IoTHubServerless" `
  --device-id "MyDummyDevice"

az iot hub device-identity show `
  -d "MyDummyDevice" `
  -n "IoTHubServerless"

$connstr = az iot hub connection-string show `
  -n "IoTHubServerless" `
  | ConvertFrom-Json 

az iot device simulate `
  --hub-name "IoTHubServerless" `
  --device-id "MyDummyDevice" `
  --login $connstr.connectionString `
  --msg-count 100

az eventhubs namespace create `
  --resource-group "ServerlessStreamingIoT" `
  --name "ServerlessNamespace" `
  --location "West Europe" `
  --sku Standard `
  --enable-auto-inflate `
  --maximum-throughput-units 20

az eventhubs eventhub create `
  --resource-group "ServerlessStreamingIoT" `
  --namespace-name "ServerlessNamespace" `
  --name "ServerlessEventhub" `
  --message-retention 4 `
  --partition-count 15

az servicebus namespace create `
  --resource-group "ServerlessStreamingIoT"`
  --name "ServerlessSBNamespace" `
  --location "West Europe" `
  --sku Standard

az servicebus queue create `
  --name "ServerlessQueue" `
  --namespace-name "ServerlessSBNamespace" `
  --resource-group "ServerlessStreamingIoT"

az stream-analytics job create `
  --name "StreamAnalyticsForDummmies" `
  --resource-group "ServerlessStreamingIoT"

az storage account create `
  --location "West Europe" `
  --name "storageiotdataServerless" `
  --resource-group "ServerlessStreamingIoT" `
  --sku Standard_LRS

az storage account keys list `
  --account-name "storageiotdataServerless"

az tsi environment gen2 create `
  --name "TimeseriesForServerless" `
  --location "West Europe" `
  --resource-group "ServerlessStreamingIoT" `
  --time-series-id-properties name=idName type=String `
  --storage-configuration `
      account-name="storageiotdataServerless" `
      management-key="<Schlüssel ihres Speicherkontos>" `
  --sku name="L1" capacity=1