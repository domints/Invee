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

namespace Invee.Application.Commands.CategoryCommands
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
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult<int>.Fail(Errors.NameEmpty());
            var cat = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.Id);
            if (cat == null)
                return OperationResult.NotFound(nameof(Category));

            cat.Name = request.Name;

            await _db.SaveChangesAsync();
            return OperationResult.Success();
        }
    }
}