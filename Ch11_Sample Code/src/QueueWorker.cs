using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.CSharp.RuntimeBinder;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using System.Data.SqlClient;
using System.Net.Http;
using System.Data;
using System.Threading.Tasks;

namespace QueueFunctions
{
  public static class ReqResQueueWorker
  {
    static readonly HttpClient client = new HttpClient();

    [FunctionName("ReqResQueueWorker")]
    public static async Task Run(
      [QueueTrigger("command-queue", Connection = "stgblobikb3lhctt5vny_STORAGE")] string myQueueItem, 
      [Queue("command-queue"),StorageAccount("stgblobikb3lhctt5vny_STORAGE")] ICollector<string> nextCommandQueue,
      [Queue("event-queue"),StorageAccount("stgblobikb3lhctt5vny_STORAGE")] ICollector<string> eventQueue,
      ILogger log)
    {
      log.LogInformation($"C# Queue trigger function processed: {myQueueItem}");

      string endpoint, loadId;
      int pageNumber, pageSize;

      try
      {
        // create a dynamic object from the queue item
        dynamic command = JObject.Parse(myQueueItem);
        // read the endpoint, page number, page size and load id from the command
        endpoint = command.endpoint;
        pageNumber = command.page_number;
        pageSize = command.page_size;
        loadId = command.load_id;
      }
      catch (RuntimeBinderException)
      {
        // if an error occurs, one of the members is not set, and the message therefore in an invalid format
        log.LogError("Error reading data from queue item, your message did not conform to the required format.");
        throw new ArgumentException("Your incoming message did not conform to the required format.");
      }
      try
      {
        // call the REST API
        HttpResponseMessage response = await client.GetAsync($"https://reqres.in{endpoint}?page={pageNumber}");
        // make sure the call did not return an error code
        response.EnsureSuccessStatusCode();
        // read the response 
        string responseBody = await response.Content.ReadAsStringAsync();
        // create an object from the response
        dynamic responseObject = JObject.Parse(responseBody);

        // create a datatable from the data member of the response object 
        var dataTable = JsonConvert.DeserializeObject<DataTable>($"{responseObject.data}");
        // add and populate the loadid column
        dataTable.Columns.Add("LoadId", typeof(Guid));
        foreach (DataRow row in dataTable.Rows)
        {
          row["LoadId"] = new Guid(loadId);
        }

        // save datatable to database
        using (SqlConnection destinationConnection = new SqlConnection("Server=tcp:sqlsrv--ikb3lhctt5vny.database.windows.net,1433;Initial Catalog=sqldb-ikb3lhctt5vny;Persist Security Info=False;User ID=sqldemoadmin;Password=!demo54321;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"))
        {
          destinationConnection.Open();
          using (SqlBulkCopy bulkCopy = new SqlBulkCopy(destinationConnection))
          {
            // prepare the bulk copy command
            bulkCopy.DestinationTableName = "staging.ReqResUsers";

            try
            {
              // Write from the datatable to the destination.
              bulkCopy.WriteToServer(dataTable);
            }
            catch (Exception ex)
            {
              log.LogError(ex.Message);
              throw;
            }
          }
        }
        
        if (dataTable.Rows.Count == pageSize)
        {
          nextCommandQueue.Add(JsonConvert.SerializeObject(
            new { 
              endpoint = endpoint, 
              page_number = pageNumber+1, 
              page_size = pageSize, 
              load_id = loadId}));
        }
        else {
          eventQueue.Add(JsonConvert.SerializeObject(
            new { 
              event_name = "load completed", 
              event_source = "ReqResQueueWorker", 
              rows_fetched = ((pageNumber-1)*pageSize)+dataTable.Rows.Count, 
              load_id = loadId }));
        }
      }
      catch (RuntimeBinderException ex)
      {
        log.LogError($"{ex.Message}, {ex.StackTrace}");
        log.LogError("Error reading data from REST API, response did not conform to the required format.");
        throw new ArgumentException("The response from the REST API did not conform to the required format.");
      }
    }
  }
}
