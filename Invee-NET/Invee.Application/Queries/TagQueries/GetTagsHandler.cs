using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.TagQueries
{
    public class GetTagsHandler : IRequestHandler<GetTags, OperationResult<List<Tag>>>
    {
        private readonly InveeContext _db;

        public GetTagsHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<Tag>>> Handle(GetTags request, CancellationToken cancellationToken)
        {
            var result = await _db.Tags.OrderBy(t => t.Name).ToListAsync(cancellationToken);
            return OperationResult.Success(result);
        }
    }
}
