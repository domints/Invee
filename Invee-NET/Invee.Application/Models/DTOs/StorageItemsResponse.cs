using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Database.Model;

namespace Invee.Application.Models.DTOs
{
    public class StorageItemsResponse
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public required StorageType Type { get; set; }
        public List<StorageListEntry> ChildStorages { get; set; } = new List<StorageListEntry>();
        public List<ItemListEntry> Items { get; set; } = new List<ItemListEntry>();
    }
}