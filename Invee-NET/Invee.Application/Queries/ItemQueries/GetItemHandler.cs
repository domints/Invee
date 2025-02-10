using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.Converters;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ItemQueries
{
    public class GetItemHandler : IRequestHandler<GetItem, OperationResult<ItemResponse>>
    {
        private readonly InveeContext _db;

        public GetItemHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<ItemResponse>> Handle(GetItem request, CancellationToken cancellationToken)
        {
            var item = await _db.Items
                .Include(i => i.Category)
                .Include(i => i.Storage)
                .Include(i => i.Borrowings)
                .FirstOrDefaultAsync(i => i.Id == request.Id);
            if (item == null)
                return OperationResult<ItemResponse>.NotFound(nameof(Item));

            var result = new ItemResponse
            {
                Id = item.Id,
                Slug = item.Slug,
                Name = item.Name,
                Note = item.Note,
                QuantityType = item.QuantityType,
                Quantity = item.QuantityType == Data.Enums.QuantityType.Precise ? item.Quantity : null,
                Level = item.QuantityType == Data.Enums.QuantityType.Levels ? (Data.Enums.QuantityLevel)item.Quantity! : null,
                Storage = item.Storage!.ToListEntry(),
                Category = new CategoryDTO
                {
                    Id = item.Category!.Id,
                    Name = item.Category.Name,
                    Slug = item.Category.Name,
                    ParentId = item.Category.ParentId
                },
                Borrowings = item.Borrowings!.Select(b => new BorrowingDTO
                {
                    Borrower = b.Borrower,
                    Start = b.Borrowed ?? b.ExpectedStart,
                    End = b.Returned ?? b.ExpectedReturn,
                    Status = b.Status,
                    Incomplete = b.Incomplete,
                    Comment = b.Comment,
                    Update = b.Status switch
                    {
                        Data.Enums.BorrowingStatus.Borrowed => b.Borrowed,
                        Data.Enums.BorrowingStatus.Cancelled => b.Returned,
                        Data.Enums.BorrowingStatus.Returned => b.Returned,
                        _ => b.Created
                    }
                }).ToList()
            };

            return OperationResult.Success(result);
        }
    }
}