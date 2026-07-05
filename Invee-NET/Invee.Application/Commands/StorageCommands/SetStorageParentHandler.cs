using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.StorageCommands
{
    public class SetStorageParentHandler : IRequestHandler<SetStorageParent, OperationResult>
    {
        private readonly InveeContext _db;

        public SetStorageParentHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(SetStorageParent request, CancellationToken cancellationToken)
        {
            var storage = await _db.Storages.FirstOrDefaultAsync(s => s.Id == request.Id, cancellationToken);
            if (storage == null)
                return OperationResult.NotFound(nameof(Storage));

            if (request.ParentId == request.Id)
                return OperationResult.Fail(Errors.InvalidMove());

            if (request.ParentId.HasValue)
            {
                var parentExists = await _db.Storages.AnyAsync(s => s.Id == request.ParentId, cancellationToken);
                if (!parentExists)
                    return OperationResult.NotFound(nameof(Storage) + "." + nameof(Storage.Parent));

                if (await IsDescendantOfAsync(request.ParentId.Value, request.Id, cancellationToken))
                    return OperationResult.Fail(Errors.InvalidMove());
            }

            storage.ParentId = request.ParentId;
            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }

        private async Task<bool> IsDescendantOfAsync(int nodeId, int ancestorId, CancellationToken cancellationToken)
        {
            var currentId = nodeId;
            while (true)
            {
                if (currentId == ancestorId)
                    return true;

                var parentId = await _db.Storages
                    .Where(s => s.Id == currentId)
                    .Select(s => s.ParentId)
                    .FirstOrDefaultAsync(cancellationToken);

                if (!parentId.HasValue)
                    return false;

                currentId = parentId.Value;
            }
        }
    }
}
