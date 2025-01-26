using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Data.Database.Model
{
    public class Category
    {
        public int Id { get; set; }
        public int? ParentId { get; set; }
        public required string Name { get; set; }

        public virtual Category? Parent { get; set; }
        public virtual ICollection<Category> Children { get; set; } = [];

        public virtual ICollection<Item> Items { get; set; } = [];
    }
}