using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.Converters;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ItemQueries
{
    public class GetAllItemsHandler : IRequestHandler<GetAllItems, OperationResult<List<ItemListEntry>>>
    {
        private readonly InveeContext _db;

        public GetAllItemsHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<ItemListEntry>>> Handle(GetAllItems request, CancellationToken cancellationToken)
        {
            var query = _db.Items.AsQueryable();
            if (!string.IsNullOrWhiteSpace(request.Search))
            {
                var term = request.Search.Trim().ToLower();
                query = query.Where(i =>
                    i.Name.ToLower().Contains(term) ||
                    (i.ItemTags != null && i.ItemTags.Any(it => it.Tag!.Name.ToLower().Contains(term))));
            }

            var items = await query.OrderBy(i => i.Name).Select(ItemConverter.ToListEntryExpr).ToListAsync(cancellationToken);
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

            var borrowedIds = await _db.Borrowings.Where(b => b.Status != Data.Enums.BorrowingStatus.Returned && b.Status != Data.Enums.BorrowingStatus.Cancelled && itemIds.Contains(b.ItemId)).Select(b => b.ItemId).ToHashSetAsync();
            items.MarkBorrowed(borrowedIds).All(_ => true); // Is this a bad way to use MarkBorrowed extension? :D

            return OperationResult.Success(items);
        }
    }
}
