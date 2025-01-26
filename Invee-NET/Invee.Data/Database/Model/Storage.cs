using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Data.Database.Model
{
    public class Storage
    {
        public int Id { get; set; }
        public int? ParentId { get; set; }
        public int TypeId { get; set; }

        public required string Name { get; set; }
        public string? Slug { get; set; }
        
        public required virtual StorageType Type { get; set; }
    }
}