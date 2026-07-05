using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ItemQueries
{
    public class LookupItemByCodeHandler : IRequestHandler<LookupItemByCode, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public LookupItemByCodeHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(LookupItemByCode request, CancellationToken cancellationToken)
        {
            var query = _db.ItemCodes.Where(c => c.Contents == request.Contents);

            if (request.CodeType.HasValue)
                query = query.Where(c => c.CodeType == request.CodeType.Value);

            var code = await query.FirstOrDefaultAsync(cancellationToken);
            if (code == null)
                return OperationResult<int>.NotFound(nameof(ItemCode));

            return OperationResult.Success(code.ItemId);
        }
    }
}
