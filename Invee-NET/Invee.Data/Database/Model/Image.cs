namespace Invee.Data.Database.Model
{
    public class Image
    {
        public int Id { get; set; }
        public required string FileName { get; set; }
        public required string ContentType { get; set; }
        public required string StoredPath { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual ICollection<ItemImage>? ItemImages { get; set; }
        public virtual ICollection<StorageImage>? StorageImages { get; set; }
    }
}
