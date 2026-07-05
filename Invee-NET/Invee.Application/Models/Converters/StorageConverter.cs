using Invee.Application.Models.DTOs;
using Invee.Data.Database.Model;

namespace Invee.Application.Models.Converters
{
    public static class StorageConverter
    {
        public static StorageListEntry ToListEntry(this Storage storage)
        {
            return new StorageListEntry
            {
                Id = storage.Id,
                Name = storage.Name,
                Slug = storage.Slug,
                Type = new StorageTypeDto { Id = storage.Type!.Id, Name = storage.Type.Name }
            };
        }

        public static List<StorageListEntry> ToListEntries(this List<Storage> storages)
        {
            return storages.Select(ToListEntry).ToList();
        }
    }
}
