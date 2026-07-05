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
    public class RenameStorageTypeHandler : IRequestHandler<RenameStorageType, OperationResult>
    {
        private readonly InveeContext _db;

        public RenameStorageTypeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(RenameStorageType request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult.Fail(Errors.NameEmpty());
            var entity = await _db.StorageTypes.FirstOrDefaultAsync(c => c.Id == request.Id);
            if (entity == null)
                return OperationResult.NotFound(nameof(StorageType));
            var isDuplicate = _db.StorageTypes.Any(c => c.Name == request.Name && c.Id != request.Id);
            if (isDuplicate)
                return OperationResult.Fail(Errors.NameDuplicate(nameof(StorageType)));

            entity.Name = request.Name;

            await _db.SaveChangesAsync();
            return OperationResult.Success();
        }
    }
}
