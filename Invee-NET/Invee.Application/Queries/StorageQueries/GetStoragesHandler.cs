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
    public class GetStoragesHandler : IRequestHandler<GetStorages, OperationResult<List<StorageTreeResponse>>>
    {
        private readonly InveeContext _db;

        public GetStoragesHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<StorageTreeResponse>>> Handle(GetStorages request, CancellationToken cancellationToken)
        {
            var result = await _db.Storages.ToListAsync(cancellationToken: cancellationToken);
            var roots = result.Where(c => c.ParentId == null).Select(c => new StorageTreeResponse 
            {
                Id = c.Id,
                Name = c.Name
            }).ToList();
            var children = result.Where(c => c.ParentId != null).GroupBy(c => c.ParentId ?? -1).ToDictionary(g => g.Key, v => v.ToList());
            foreach (var root in roots)
                FillChildren(root, children);
            return OperationResult.Success(roots);
        }

        private void FillChildren(StorageTreeResponse category, Dictionary<int, List<Storage>> categories)
        {
            if (categories.ContainsKey(category.Id))
            {
                category.Children = categories[category.Id].Select(c => new StorageTreeResponse
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