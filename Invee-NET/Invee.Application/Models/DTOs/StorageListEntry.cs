namespace Invee.Application.Models.DTOs
{
    public class StorageListEntry
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public string? Slug { get; set; }
        public required StorageTypeDto Type { get; set; }
    }
}
