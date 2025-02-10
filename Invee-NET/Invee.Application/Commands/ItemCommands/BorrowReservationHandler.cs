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
    public class BorrowReservationHandler : IRequestHandler<BorrowReservation, OperationResult>
    {
        private readonly InveeContext _db;

        public BorrowReservationHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(BorrowReservation request, CancellationToken cancellationToken)
        {
            var reservation = await _db.Borrowings.FirstOrDefaultAsync(b => b.ItemId == request.Id && b.Status == Data.Enums.BorrowingStatus.Reserved, cancellationToken);
            if (reservation == null)
            {
                return OperationResult.NotFound(nameof(Borrowing));
            }

            reservation.Borrowed = DateTime.UtcNow;
            reservation.Status = Data.Enums.BorrowingStatus.Borrowed;
            await _db.SaveChangesAsync();
            return OperationResult.Success();
        }
    }
}