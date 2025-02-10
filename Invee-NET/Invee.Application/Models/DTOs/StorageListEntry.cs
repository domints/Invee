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
}