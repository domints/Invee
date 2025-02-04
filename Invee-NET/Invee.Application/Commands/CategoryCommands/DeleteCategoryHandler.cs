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
    public class DeleteCategoryHandler : IRequestHandler<DeleteCategory, OperationResult>
    {
        private readonly InveeContext _db;

        public DeleteCategoryHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(DeleteCategory request, CancellationToken cancellationToken)
        {
            var cat = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.Id);
            if (cat == null)
                return OperationResult.NotFound(nameof(Category));

            _db.Categories.Remove(cat);
            await _db.SaveChangesAsync();

            return OperationResult.Success();
        }
    }
}