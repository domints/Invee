using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class AddItemCodeHandler : IRequestHandler<AddItemCode, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public AddItemCodeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(AddItemCode request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Contents))
                return OperationResult<int>.Fail(Errors.ContentsEmpty());

            var itemExists = await _db.Items.AnyAsync(i => i.Id == request.Id, cancellationToken);
            if (!itemExists)
                return OperationResult<int>.NotFound(nameof(Item));

            var entity = new ItemCode
            {
                ItemId = request.Id,
                CodeType = request.CodeType,
                Contents = request.Contents
            };

            _db.ItemCodes.Add(entity);
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success(entity.Id);
        }
    }
}
