using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Commands.StorageTypeCommands
{
    public class CreateStorageTypeHandler : IRequestHandler<CreateStorageType, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public CreateStorageTypeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(CreateStorageType request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult<int>.Fail(Errors.NameEmpty());
            var isDuplicate = _db.StorageTypes.Any(c => c.Name == request.Name);
            if (isDuplicate)
                return OperationResult<int>.Fail(Errors.NameDuplicate(nameof(StorageType)));

            var entity = new StorageType
            {
                Name = request.Name
            };

            _db.StorageTypes.Add(entity);
            await _db.SaveChangesAsync();

            return OperationResult.Success(entity.Id);
        }
    }
}