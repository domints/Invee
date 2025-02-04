using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models.DTOs
{
    public class CategoryDTO
    {
        public int Id { get; set; }
        public int? ParentId { get; set; }
        public required string Name { get; set; }

        public string? Slug { get; set; }
    }
}