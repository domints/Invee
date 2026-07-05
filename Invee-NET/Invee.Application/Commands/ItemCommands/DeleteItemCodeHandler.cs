using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class DeleteItemCodeHandler : IRequestHandler<DeleteItemCode, OperationResult>
    {
        private readonly InveeContext _db;

        public DeleteItemCodeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(DeleteItemCode request, CancellationToken cancellationToken)
        {
            var code = await _db.ItemCodes.FirstOrDefaultAsync(c => c.Id == request.CodeId && c.ItemId == request.Id, cancellationToken);
            if (code == null)
                return OperationResult.NotFound(nameof(ItemCode));

            _db.ItemCodes.Remove(code);
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success();
        }
    }
}
