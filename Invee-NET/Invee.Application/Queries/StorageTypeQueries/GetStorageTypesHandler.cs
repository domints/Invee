using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.StorageTypeQueries
{
    public class GetStorageTypesHandler : IRequestHandler<GetStorageTypes, OperationResult<List<StorageType>>>
    {
        private readonly InveeContext _db;

        public GetStorageTypesHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<StorageType>>> Handle(GetStorageTypes request, CancellationToken cancellationToken)
        {
            var result = await _db.StorageTypes.ToListAsync(cancellationToken: cancellationToken);

            return OperationResult.Success(result);
        }
    }
}