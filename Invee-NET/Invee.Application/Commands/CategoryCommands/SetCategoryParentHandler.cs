using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
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
            var cat = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.Id);
            if (cat == null)
                return OperationResult.NotFound(nameof(Category));

            var parentExists = !request.ParentId.HasValue || await _db.Categories.AnyAsync(c => c.Id == request.ParentId);
            if (!parentExists)
                return OperationResult.NotFound(nameof(Category) + "." + nameof(Category.Parent));

            cat.ParentId = request.ParentId;
            await _db.SaveChangesAsync();
            return OperationResult.Success();
        }
    }
}