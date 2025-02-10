using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class ReturnItemHandler : IRequestHandler<ReturnItem, OperationResult>
    {
        private readonly InveeContext _db;

        public ReturnItemHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(ReturnItem request, CancellationToken cancellationToken)
        {
            var borrowing = await _db.Borrowings.FirstOrDefaultAsync(b => b.ItemId == request.Id && b.Status == Data.Enums.BorrowingStatus.Borrowed, cancellationToken);
            if (borrowing == null)
            {
                return OperationResult.NotFound(nameof(Borrowing));
            }

            borrowing.Status = Data.Enums.BorrowingStatus.Returned;
            borrowing.Returned = DateTime.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}