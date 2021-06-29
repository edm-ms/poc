using Azure.Storage.Blobs.Models;
using System;

namespace Client.Models
{
    public class FileModel
    {

        public String BlobDescription;
        public String SizeInMB;
        public String SizeInGB;
        public BlobItem BlobItem { get; set; }

        public Uri Uri { get; set; }

    }
}
