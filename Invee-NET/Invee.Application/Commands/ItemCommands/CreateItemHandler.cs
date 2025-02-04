using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public class CreateItemHandler : IRequestHandler<CreateItem, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public CreateItemHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(CreateItem request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult<int>.Fail(Errors.NameEmpty());
            var isDuplicate = _db.Items.Any(i => i.Name == request.Name);
            if (isDuplicate)
                return OperationResult<int>.Fail(Errors.NameDuplicate(nameof(Item)));
            
            if (request.Slug != null)
            {
                var slugDuplicate = _db.Storages.Any(i => i.Slug == request.Slug);
                if (slugDuplicate)
                    return OperationResult<int>.Fail(Errors.SlugDuplicate(nameof(Item)));
            }

            var storageExists = _db.Storages.Any(st => st.Id == request.StorageId);
            if (!storageExists)
                return OperationResult<int>.NotFound(nameof(Storage));

            var categoryExists = _db.Categories.Any(cat => cat.Id == request.CategoryId);
            if (!categoryExists)
                return OperationResult<int>.NotFound(nameof(Category));

            var entity = new Item
            {
                Name = request.Name,
                Slug = request.Slug,
                CategoryId = request.CategoryId,
                StorageId = request.StorageId
            };

            _db.Items.Add(entity);
            await _db.SaveChangesAsync();

            return OperationResult.Success(entity.Id);
        }
    }
}