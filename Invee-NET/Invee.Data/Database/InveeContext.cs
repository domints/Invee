using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Database.Model;
using Microsoft.EntityFrameworkCore;

namespace Invee.Data.Database
{
    public class InveeContext : DbContext
    {
        public InveeContext (DbContextOptions<InveeContext> options)
            : base(options)
        {
        }
        
        public required DbSet<Borrowing> Borrowings { get; set; }
        public required DbSet<Category> Categories { get; set; }
        public required DbSet<Item> Items { get; set; }
        public required DbSet<Storage> Storages { get; set; }
        public required DbSet<StorageType> StorageTypes { get; set; }
    }
}