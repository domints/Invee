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
    public class GetCategoryHandler : IRequestHandler<GetCategory, OperationResult<CategoryDTO>>
    {
        private readonly InveeContext _db;

        public GetCategoryHandler(InveeContext db)
        {
            _db = db;
        }
        
        public async Task<OperationResult<CategoryDTO>> Handle(GetCategory request, CancellationToken cancellationToken)
        {
            var result = await _db.Categories.Where(c => c.Id == request.Id).FirstOrDefaultAsync(cancellationToken: cancellationToken);
            if (result == null)
                return OperationResult<CategoryDTO>.NotFound(nameof(Category));

            return OperationResult.Success(new CategoryDTO
            {
                Id = result.Id,
                Name = result.Name,
                ParentId = result.ParentId,
                Slug = result.Slug
            });
        }
    }
}