using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.CategoryCommands
{
    public class RenameCategoryHandler : IRequestHandler<RenameCategory, OperationResult>
    {
        private readonly InveeContext _db;

        public RenameCategoryHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(RenameCategory request, CancellationToken cancellationToken)
        {
            var cat = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.Id);
            if (cat == null)
                return OperationResult.NotFound();

            cat.Name = request.Name;

            await _db.SaveChangesAsync();
            return OperationResult.Success();
        }
    }
}