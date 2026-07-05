using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class UpdateItemCodeHandler : IRequestHandler<UpdateItemCode, OperationResult>
    {
        private readonly InveeContext _db;

        public UpdateItemCodeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(UpdateItemCode request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Contents))
                return OperationResult.Fail(Errors.ContentsEmpty());

            var code = await _db.ItemCodes.FirstOrDefaultAsync(c => c.Id == request.CodeId && c.ItemId == request.Id, cancellationToken);
            if (code == null)
                return OperationResult.NotFound(nameof(ItemCode));

            code.CodeType = request.CodeType;
            code.Contents = request.Contents;

            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success();
        }
    }
}
