using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.StorageCommands
{
    public class DeleteStorageHandler : IRequestHandler<DeleteStorage, OperationResult>
    {
        private readonly InveeContext _db;

        public DeleteStorageHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(DeleteStorage request, CancellationToken cancellationToken)
        {
            var entity = await _db.Storages.FirstOrDefaultAsync(s => s.Id == request.Id, cancellationToken);
            if (entity == null)
                return OperationResult.NotFound(nameof(Storage));

            var hasItems = await _db.Items.AnyAsync(i => i.StorageId == request.Id, cancellationToken);
            if (hasItems)
                return OperationResult.Fail(Errors.InUse(nameof(Storage)));

            var hasChildren = await _db.Storages.AnyAsync(s => s.ParentId == request.Id, cancellationToken);
            if (hasChildren)
                return OperationResult.Fail(Errors.InUse(nameof(Storage)));

            _db.Storages.Remove(entity);
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success();
        }
    }
}
