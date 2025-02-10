using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;
using Invee.Application.Models.DTOs;
using Invee.Data.Database.Model;

namespace Invee.Application.Models.Converters
{
    public static class ItemConverter
    {
        private static Func<Item, ItemListEntry>? _toListEntry;

        public static Func<Item, ItemListEntry> ToListEntry => _toListEntry ??= ToListEntryExpr.Compile();

        public static Expression<Func<Item, ItemListEntry>> ToListEntryExpr => i => new ItemListEntry
        {
            Id = i.Id,
            Name = i.Name,
            Slug = i.Slug,
            QuantityType = i.QuantityType,
            Quantity = i.QuantityType == Data.Enums.QuantityType.Precise ? i.Quantity : null,
            Level = i.QuantityType == Data.Enums.QuantityType.Levels ? (Data.Enums.QuantityLevel)i.Quantity! : null,
            Broken = i.Broken
        };

        public static IEnumerable<ItemListEntry> MarkBorrowed(this IEnumerable<ItemListEntry> items, HashSet<int> borrowedIds)
        {
            foreach (var item in items)
            {
                item.Borrowed = borrowedIds.Contains(item.Id);
                yield return item;
            }
        }
    }
}