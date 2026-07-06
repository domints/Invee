using System.Diagnostics.CodeAnalysis;
using System.Text.Json;
using Invee.Data.Database.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

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
        public required DbSet<CachedProduct> CachedProducts { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            var tagsConverter = new ValueConverter<List<string>, string>(
                v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new List<string>()
            );

            var tagsComparer = new ValueComparer<List<string>>(
                (a, b) => a != null && b != null && a.SequenceEqual(b),
                v => v.Aggregate(0, (a, b) => HashCode.Combine(a, b.GetHashCode())),
                v => v.ToList()
            );

            modelBuilder.Entity<CachedProduct>(entity =>
            {
                entity.HasIndex(e => e.Barcode).IsUnique();
                entity.Property(e => e.Tags)
                    .HasConversion(tagsConverter)
                    .Metadata.SetValueComparer(tagsComparer);
            });
        }
    }
}