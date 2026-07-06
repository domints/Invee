namespace Invee.Data.Database.Model
{
    public class CachedProduct
    {
        public int Id { get; set; }
        public required string Barcode { get; set; }
        public required string ProductName { get; set; }
        public List<string> Tags { get; set; } = [];
        public string? FrontImageUrl { get; set; }
        public required string DataSource { get; set; }
        public required string RawJson { get; set; }
        public DateTime CachedAt { get; set; }
    }
}
