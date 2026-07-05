using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.StorageTypeQueries
{
    public class GetStorageTypesHandler : IRequestHandler<GetStorageTypes, OperationResult<List<StorageTypeDto>>>
    {
        private readonly InveeContext _db;

        public GetStorageTypesHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<StorageTypeDto>>> Handle(GetStorageTypes request, CancellationToken cancellationToken)
        {
            var result = await _db.StorageTypes
                .Select(st => new StorageTypeDto { Id = st.Id, Name = st.Name })
                .ToListAsync(cancellationToken);

            return OperationResult.Success(result);
        }
    }
}
