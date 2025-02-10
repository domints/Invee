using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class ReserveItemHandler : IRequestHandler<ReserveItem, OperationResult>
    {
        private readonly InveeContext _db;

        public ReserveItemHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(ReserveItem request, CancellationToken cancellationToken)
        {
            var isBlocked = await _db.Borrowings.AnyAsync(b => b.ItemId == request.Id && b.Status != Data.Enums.BorrowingStatus.Returned && b.Status != Data.Enums.BorrowingStatus.Cancelled, cancellationToken);
            if (isBlocked)
            {
                return OperationResult.Fail(Errors.ReservedOrBorrowed());
            }

            var borrowing = new Borrowing
            {
                Borrower = request.BorrowerName,
                ExpectedStart = request.ExpectedStart,
                ExpectedReturn = request.ExpectedReturn,
                ItemId = request.Id,
                Created = DateTime.UtcNow,
                Incomplete = request.Incomplete,
                Comment = request.Comment
            };

            _db.Borrowings.Add(borrowing);
            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}