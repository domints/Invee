using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models.DTOs
{
    public class CategoryTreeResponse
    {
        public int Id { get; set; }
        public int? ParentId { get; set; }
        public required string Name { get; set; }
        public List<CategoryTreeResponse> Children { get; set; } = new List<CategoryTreeResponse>();
    }
}