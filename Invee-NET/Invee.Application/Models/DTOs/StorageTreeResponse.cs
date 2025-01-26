using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models.DTOs
{
    public class StorageTreeResponse
    {
        public int Id { get; set; }
        public int? ParentId { get; set; }
        public required string Name { get; set; }
        public List<StorageTreeResponse> Children { get; set; } = new List<StorageTreeResponse>();
    }
}