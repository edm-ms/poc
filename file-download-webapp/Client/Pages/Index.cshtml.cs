using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using Client.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace Client.Pages
{
    [Authorize]
    public class IndexModel : PageModel
    {

        private readonly IConfiguration _configuration;

        public IList<FileModel> Files { get; set; } = new List<FileModel>();

        public IndexModel(
            IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public DateTime sasStartTime = DateTime.UtcNow;
        public String blobDescription = String.Empty;
        public String sizeInMB = String.Empty;
        public String sizeInGB = String.Empty;
        
        public async Task OnGet()
        {
            var blobServiceClient =
                new BlobServiceClient(_configuration["AZURE_STORAGE_CONNECTION_STRING"]);

            BlobContainerClient blobContainerClient =
                blobServiceClient.GetBlobContainerClient(_configuration["AZURE_STORAGE_CONTAINER"]);
            Uri uri = null;

            await foreach (var blobItem in blobContainerClient.GetBlobsAsync())
            {

                // Get file size in bytes
                long? blobSize = blobItem.Properties.ContentLength;

                // Convert long to decimal
                decimal decBlobSize = Convert.ToDecimal(blobSize);

                // Divide by 1024 to convert bytes to MB and again for GB
                decimal decSizeInMB = decBlobSize / 1024;
                decimal decSizeInGB = decBlobSize / 1024 / 1024;

                // Convert to string and format number with a comma
                sizeInMB = decSizeInMB.ToString("N");
                sizeInGB = decSizeInGB.ToString("N");

                BlobClient blobClient = blobContainerClient.GetBlobClient(blobItem.Name);

                // Retreive all user-defined metadata for blob
                BlobProperties properties = await blobClient.GetPropertiesAsync();

                // Reset metaData variable
                blobDescription = String.Empty;
                
                // Loop through all metadata and find key named "description"
                foreach (var metadataItem in properties.Metadata)
                    if (metadataItem.Key == "description" || metadataItem.Key == "Description")
                    {
                        // Set blobDescription information if name matches "description" or "Description"
                        blobDescription = metadataItem.Value;
                    }

                if (_configuration["SAS_GENERATION_METHOD"] == "logicapp")
                {
                    var url = _configuration["AZURE_LOGIC_APP_URL"];

                    using HttpClient client = new HttpClient();
                    using HttpResponseMessage res = await client.GetAsync(string.Format(_configuration["AZURE_LOGIC_APP_URL"], blobItem.Name));
                    using HttpContent content = res.Content;
                    uri = new Uri(await content.ReadAsStringAsync());
                }
                else
                {
                    BlobSasBuilder blobSasBuilder = new BlobSasBuilder()
                    {
                        BlobContainerName = blobContainerClient.Name,
                        BlobName = blobItem.Name
                    };

                    if (string.IsNullOrWhiteSpace(_configuration["AZURE_STORAGE_STORED_POLICY_NAME"]))
                    {
                        blobSasBuilder.StartsOn = DateTime.UtcNow;
                        blobSasBuilder.ExpiresOn = DateTime.UtcNow.AddMinutes(Convert.ToInt32(_configuration["AZURE_STORAGE_SAS_TOKEN_DURATION"]));
                        blobSasBuilder.SetPermissions(BlobSasPermissions.Read);
                    }
                    else
                    {
                        blobSasBuilder.Identifier = _configuration["AZURE_STORAGE_STORED_POLICY_NAME"];
                    }

                    uri = blobClient.GenerateSasUri(blobSasBuilder);
                }

                this.Files.Add(new FileModel() { BlobItem = blobItem, Uri = uri, BlobDescription = blobDescription, SizeInMB = sizeInMB, SizeInGB = sizeInGB });
            }
        }
    }
}