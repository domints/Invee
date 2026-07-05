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

namespace Invee.Application.Commands.StorageTypeCommands
{
    public class DeleteStorageTypeHandler : IRequestHandler<DeleteStorageType, OperationResult>
    {
        private readonly InveeContext _db;

        public DeleteStorageTypeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(DeleteStorageType request, CancellationToken cancellationToken)
        {
            var entity = await _db.StorageTypes.FirstOrDefaultAsync(c => c.Id == request.Id);
            if (entity == null)
                return OperationResult.NotFound(nameof(StorageType));
            var inUse = _db.Storages.Any(s => s.TypeId == request.Id);
            if (inUse)
                return OperationResult.Fail(Errors.InUse(nameof(StorageType)));

            _db.StorageTypes.Remove(entity);
            await _db.SaveChangesAsync();

            return OperationResult.Success();
        }
    }
}
