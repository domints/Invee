using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.StorageQueries
{
    public class GetStorageHandler : IRequestHandler<GetStorage, OperationResult<StorageItemsResponse>>
    {
        private readonly InveeContext _db;

        public GetStorageHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<StorageItemsResponse>> Handle(GetStorage request, CancellationToken cancellationToken)
        {
            var storage = await _db.Storages.Include(s => s.Type).Include(s => s.Parent).FirstOrDefaultAsync(s => s.Id == request.Id, cancellationToken: cancellationToken);
            if (storage == null)
                return OperationResult<StorageItemsResponse>.NotFound(nameof(Storage));

            var childStorages = await _db.Storages.Include(s => s.Type).Where(s => s.ParentId == request.Id).ToListAsync(cancellationToken: cancellationToken);
            var items = await _db.Items.Where(i => i.StorageId == request.Id).ToListAsync(cancellationToken: cancellationToken);

            var result = new StorageItemsResponse
            {
                Id = storage.Id,
                Name = storage.Name,
                Type = storage.Type!,
                ParentId = storage?.Parent?.Id,
                ParentSlug = storage?.Parent?.Slug,
                ChildStorages = childStorages.ToListEntries(),
                Items = items.Select(i => new ItemListEntry
                {
                    Id = i.Id,
                    Name = i.Name,
                    Slug = i.Slug,
                    QuantityType = i.QuantityType,
                    Quantity = i.QuantityType == Data.Enums.QuantityType.Precise ? i.Quantity : null,
                    Level = i.QuantityType == Data.Enums.QuantityType.Levels ? (Data.Enums.QuantityLevel)i.Quantity! : null
                }).ToList()
            };

            return OperationResult.Success(result);
        }
    }
}