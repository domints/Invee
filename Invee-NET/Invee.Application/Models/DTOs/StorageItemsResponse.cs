namespace Invee.Application.Models.DTOs
{
    public class StorageItemsResponse
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public required StorageTypeDto Type { get; set; }
        public int? ParentId { get; set; }
        public string? ParentSlug { get; set; }
        public List<StorageListEntry> ChildStorages { get; set; } = new List<StorageListEntry>();
        public List<ItemListEntry> Items { get; set; } = new List<ItemListEntry>();
        public List<ImageDto> Images { get; set; } = new List<ImageDto>();
    }
}
