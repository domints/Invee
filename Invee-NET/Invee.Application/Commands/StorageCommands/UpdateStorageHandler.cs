using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.StorageCommands
{
    public class UpdateStorageHandler : IRequestHandler<UpdateStorage, OperationResult>
    {
        private readonly InveeContext _db;

        public UpdateStorageHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(UpdateStorage request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult.Fail(Errors.NameEmpty());

            var entity = await _db.Storages.FirstOrDefaultAsync(s => s.Id == request.Id, cancellationToken);
            if (entity == null)
                return OperationResult.NotFound(nameof(Storage));

            var isDuplicate = _db.Storages.Any(s => s.Name == request.Name && s.Id != request.Id);
            if (isDuplicate)
                return OperationResult.Fail(Errors.NameDuplicate(nameof(Storage)));

            var typeExists = await _db.StorageTypes.AnyAsync(st => st.Id == request.StorageTypeId, cancellationToken);
            if (!typeExists)
                return OperationResult.NotFound(nameof(StorageType));

            entity.Name = request.Name;
            entity.TypeId = request.StorageTypeId;

            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}
