using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class UpdateItemHandler : IRequestHandler<UpdateItem, OperationResult>
    {
        private readonly InveeContext _db;

        public UpdateItemHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(UpdateItem request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult.Fail(Errors.NameEmpty());

            var entity = await _db.Items.FirstOrDefaultAsync(i => i.Id == request.Id, cancellationToken);
            if (entity == null)
                return OperationResult.NotFound(nameof(Item));

            var isDuplicate = _db.Items.Any(i => i.Name == request.Name && i.Id != request.Id);
            if (isDuplicate)
                return OperationResult.Fail(Errors.NameDuplicate(nameof(Item)));

            if (request.Slug != null)
            {
                var slugDuplicate = _db.Items.Any(i => i.Slug == request.Slug && i.Id != request.Id);
                if (slugDuplicate)
                    return OperationResult.Fail(Errors.SlugDuplicate(nameof(Item)));
            }

            var storageExists = await _db.Storages.AnyAsync(st => st.Id == request.StorageId, cancellationToken);
            if (!storageExists)
                return OperationResult.NotFound(nameof(Storage));

            var categoryExists = await _db.Categories.AnyAsync(cat => cat.Id == request.CategoryId, cancellationToken);
            if (!categoryExists)
                return OperationResult.NotFound(nameof(Category));

            entity.Name = request.Name;
            entity.Slug = request.Slug;
            entity.Note = request.Note;
            entity.CategoryId = request.CategoryId;
            entity.StorageId = request.StorageId;
            entity.QuantityType = request.QuantityType;
            entity.Quantity = request.Quantity;
            entity.Broken = request.Broken;
            entity.ExpiresAt = request.ExpiresAt;

            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}
