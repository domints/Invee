using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Enums;

namespace Invee.Application.Models.DTOs
{
    public class ItemListEntry
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public string? Slug { get; set; }
        public QuantityType QuantityType { get; set; }
        public decimal? Quantity { get; set; }
        public QuantityLevel? Level { get; set; }
    }
}