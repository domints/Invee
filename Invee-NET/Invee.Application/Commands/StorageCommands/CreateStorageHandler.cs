using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Commands.StorageCommands
{
    public class CreateStorageHandler : IRequestHandler<CreateStorage, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public CreateStorageHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(CreateStorage request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult<int>.Fail(["Storage name cannot be empty"]);
            var isDuplicate = _db.Storages.Any(s => s.Name == request.Name);
            if (isDuplicate)
                return OperationResult<int>.Fail(["Storage with such name already exists"]);
            
            if (request.Slug != null)
            {
                var slugDuplicate = _db.Storages.Any(s => s.Slug == request.Slug);
                if (slugDuplicate)
                    return OperationResult<int>.Fail(["Storage with such slug already exists"]);
            }

            if (request.ParentId != null)
            {
                var parentExists = _db.Storages.Any(s => s.Id == request.ParentId);
                if (!parentExists)
                    return OperationResult<int>.NotFound();
            }

            var typeExists = _db.StorageTypes.Any(st => st.Id == request.StorageTypeId);
            if (!typeExists)
                return OperationResult<int>.NotFound();

            var entity = new Storage
            {
                Name = request.Name,
                TypeId = request.StorageTypeId,
                Slug = request.Slug,
                ParentId = request.ParentId
            };

            _db.Storages.Add(entity);
            await _db.SaveChangesAsync();

            return OperationResult.Success(entity.Id);
        }
    }
}