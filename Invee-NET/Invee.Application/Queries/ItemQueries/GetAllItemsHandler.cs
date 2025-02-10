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
            var items = await _db.Items.OrderBy(i => i.Name).Select(ItemConverter.ToListEntryExpr).ToListAsync(cancellationToken);
            var itemIds = items.Select(i => i.Id).ToArray();
            var borrowedIds = await _db.Borrowings.Where(b => b.Status != Data.Enums.BorrowingStatus.Returned && itemIds.Contains(b.ItemId)).Select(b => b.ItemId).ToHashSetAsync();
            items.MarkBorrowed(borrowedIds).All(_ => true); // Is this a bad way to use MarkBorrowed extension? :D

            return OperationResult.Success(items);
        }
    }
}