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

namespace Invee.Application.Queries.CategoryQueries
{
    public class GetCategoryTreeHandler : IRequestHandler<GetCategoryTree, OperationResult<List<CategoryTreeResponse>>>
    {
        private readonly InveeContext _db;

        public GetCategoryTreeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<CategoryTreeResponse>>> Handle(GetCategoryTree request, CancellationToken cancellationToken)
        {
            var result = await _db.Categories.ToListAsync(cancellationToken: cancellationToken);
            var roots = result.Where(c => c.ParentId == null).Select(c => new CategoryTreeResponse 
            {
                Id = c.Id,
                Name = c.Name
            }).ToList();
            var children = result.Where(c => c.ParentId != null).GroupBy(c => c.ParentId ?? -1).ToDictionary(g => g.Key, v => v.ToList());
            foreach (var root in roots)
                FillChildren(root, children);
            return OperationResult.Success(roots);
        }

        private void FillChildren(CategoryTreeResponse category, Dictionary<int, List<Category>> categories)
        {
            if (categories.ContainsKey(category.Id))
            {
                category.Children = categories[category.Id].Select(c => new CategoryTreeResponse
                {
                    Id = c.Id,
                    Name = c.Name,
                    ParentId = category.Id
                }).ToList();

                foreach (var c in category.Children)
                    FillChildren(c, categories);
            }
        }
    }
}