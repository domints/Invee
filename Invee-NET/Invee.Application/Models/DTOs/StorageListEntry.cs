using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Database.Model;

namespace Invee.Application.Models.DTOs
{
    public class StorageListEntry
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public string? Slug { get; set; }
        public required StorageType Type { get; set; }
    }

    public static class StorageListEntryConverter
    {
        public static List<StorageListEntry> ToListEntries(this List<Storage> storages)
        {
            return storages.Select(c => new StorageListEntry
            {
                Id = c.Id,
                Name = c.Name,
                Slug = c.Slug,
                Type = c.Type!
            }).ToList();
        }
    }
}