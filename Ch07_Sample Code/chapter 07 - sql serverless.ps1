az group create `
  --location "East US" `
  --name "ServerlessSqlDatabase"


az sql server create `
  --name "serverless-sql" `
  --resource-group "ServerlessSqlDatabase" `
  --location "East US" `
  --admin-user "sqluser" `
  --admin-password "Pa$$w01rd"


az sql db create `
    --name "myserverlessdb" `
    --resource-group "ServerlessSqlDatabase" `
    --server "serverless-sql" `
    --sample-name "AdventureWorksLT" `
    --edition GeneralPurpose `
    --family Gen5 `
    --min-capacity 1 `
    --capacity 5 `
    --compute-model Serverless `
    --auto-pause-delay 60

az sql server firewall-rule create `
    --resource-group "ServerlessSqlDatabase" `
    --server "serverless-sql" `
    --name "accessserverlesssql" `
    --start-ip-address 37.24.63.178 `
    --end-ip-address 37.24.63.178