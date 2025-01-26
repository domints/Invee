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
    public class CreateCategoryHandler : IRequestHandler<CreateCategory, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public CreateCategoryHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(CreateCategory request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult<int>.Fail(["Category name cannot be empty"]);
            var isDuplicate = _db.Categories.Any(c => c.Name == request.Name);
            if (isDuplicate)
                return OperationResult<int>.Fail(["Category with such name already exists"]);
            var parentExists = !request.ParentId.HasValue || await _db.Categories.AnyAsync(c => c.Id == request.ParentId);
            if (!parentExists)
                return OperationResult<int>.NotFound();
            
            if (request.Slug != null)
            {
                var slugDuplicate = _db.Categories.Any(c => c.Slug == request.Slug);
                if (slugDuplicate)
                    return OperationResult<int>.Fail(["Category with such slug already exists"]);
            }

            var newCategory = new Category
            {
                Name = request.Name,
                ParentId = request.ParentId,
                Slug = request.Slug
            };

            _db.Categories.Add(newCategory);
            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success(newCategory.Id);
        }
    }
}