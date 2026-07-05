using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.CategoryCommands
{
    public class SetCategoryParentHandler : IRequestHandler<SetCategoryParent, OperationResult>
    {
        private readonly InveeContext _db;

        public SetCategoryParentHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(SetCategoryParent request, CancellationToken cancellationToken)
        {
            var cat = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.Id, cancellationToken);
            if (cat == null)
                return OperationResult.NotFound(nameof(Category));

            if (request.ParentId == request.Id)
                return OperationResult.Fail(Errors.InvalidMove());

            if (request.ParentId.HasValue)
            {
                var parentExists = await _db.Categories.AnyAsync(c => c.Id == request.ParentId, cancellationToken);
                if (!parentExists)
                    return OperationResult.NotFound(nameof(Category) + "." + nameof(Category.Parent));

                if (await IsDescendantOfAsync(request.ParentId.Value, request.Id, cancellationToken))
                    return OperationResult.Fail(Errors.InvalidMove());
            }

            cat.ParentId = request.ParentId;
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

                var parentId = await _db.Categories
                    .Where(c => c.Id == currentId)
                    .Select(c => c.ParentId)
                    .FirstOrDefaultAsync(cancellationToken);

                if (!parentId.HasValue)
                    return false;

                currentId = parentId.Value;
            }
        }
    }
}
