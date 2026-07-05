using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.TagQueries
{
    public class GetTagsHandler : IRequestHandler<GetTags, OperationResult<List<TagDto>>>
    {
        private readonly InveeContext _db;

        public GetTagsHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<List<TagDto>>> Handle(GetTags request, CancellationToken cancellationToken)
        {
            var result = await _db.Tags
                .OrderBy(t => t.Name)
                .Select(t => new TagDto { Id = t.Id, Name = t.Name })
                .ToListAsync(cancellationToken);

            return OperationResult.Success(result);
        }
    }
}
