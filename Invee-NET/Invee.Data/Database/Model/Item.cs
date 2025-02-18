using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Enums;

namespace Invee.Data.Database.Model
{
    public class Item
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public int CategoryId { get; set; }
        public int StorageId { get; set; }
        public decimal? Quantity { get; set; }
        public QuantityType QuantityType { get; set; }
        public string? Note { get; set; }
        public string? Slug { get; set; }
        public bool Broken { get; set; }

        public virtual Category? Category { get; set; }
        public virtual Storage? Storage { get; set; }

        public virtual ICollection<Borrowing>? Borrowings { get; set; }
    }
}