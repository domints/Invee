using System.Diagnostics.CodeAnalysis;
using Invee.Data.Database.Model;
using Microsoft.EntityFrameworkCore;

namespace Invee.Data.Database
{
    public class InveeContext : DbContext
    {
        [SetsRequiredMembers]
        public InveeContext (DbContextOptions<InveeContext> options)
            : base(options)
        {
        }
        
        public required DbSet<Borrowing> Borrowings { get; set; }
        public required DbSet<Category> Categories { get; set; }
        public required DbSet<Item> Items { get; set; }
        public required DbSet<Storage> Storages { get; set; }
        public required DbSet<StorageType> StorageTypes { get; set; }
        public required DbSet<Tag> Tags { get; set; }
        public required DbSet<ItemTag> ItemTags { get; set; }
        public required DbSet<ItemCode> ItemCodes { get; set; }
        public required DbSet<Image> Images { get; set; }
        public required DbSet<ItemImage> ItemImages { get; set; }
        public required DbSet<StorageImage> StorageImages { get; set; }
    }
}