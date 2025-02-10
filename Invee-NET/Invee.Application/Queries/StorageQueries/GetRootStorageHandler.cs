using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.Converters;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.StorageQueries
{
    public class GetRootStorageHandler : IRequestHandler<GetRootStorage, OperationResult<List<StorageListEntry>>>
    {
        private readonly InveeContext _db;

        public GetRootStorageHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<StorageListEntry>>> Handle(GetRootStorage request, CancellationToken cancellationToken)
        {
            var storages = await _db.Storages.Include(s => s.Type).Where(s => s.ParentId == null).ToListAsync(cancellationToken: cancellationToken);

            var result = storages.ToListEntries();

            return OperationResult.Success(result);
        }
    }
}