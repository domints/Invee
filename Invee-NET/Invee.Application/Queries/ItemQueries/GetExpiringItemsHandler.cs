using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.Converters;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ItemQueries
{
    public class GetExpiringItemsHandler : IRequestHandler<GetExpiringItems, OperationResult<List<ItemListEntry>>>
    {
        private readonly InveeContext _db;

        public GetExpiringItemsHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<ItemListEntry>>> Handle(GetExpiringItems request, CancellationToken cancellationToken)
        {
            var threshold = DateTime.UtcNow.AddDays(7);

            var items = await _db.Items
                .Where(i => i.ExpiresAt != null && i.ExpiresAt <= threshold)
                .OrderBy(i => i.ExpiresAt)
                .Select(ItemConverter.ToListEntryExpr)
                .ToListAsync(cancellationToken);

            var itemIds = items.Select(i => i.Id).ToArray();

            var tagsByItem = await _db.ItemTags
                .Where(it => itemIds.Contains(it.ItemId))
                .Select(it => new { it.ItemId, it.Tag!.Name })
                .ToListAsync(cancellationToken);

            var tagsLookup = tagsByItem
                .GroupBy(t => t.ItemId)
                .ToDictionary(g => g.Key, g => g.Select(t => t.Name).OrderBy(n => n).ToList());

            foreach (var item in items)
            {
                if (tagsLookup.TryGetValue(item.Id, out var tags))
                    item.Tags = tags;
            }

            var borrowedIds = await _db.Borrowings
                .Where(b => b.Status != Data.Enums.BorrowingStatus.Returned
                         && b.Status != Data.Enums.BorrowingStatus.Cancelled
                         && itemIds.Contains(b.ItemId))
                .Select(b => b.ItemId)
                .ToHashSetAsync(cancellationToken);

            items.MarkBorrowed(borrowedIds).All(_ => true);

            return OperationResult.Success(items);
        }
    }
}
