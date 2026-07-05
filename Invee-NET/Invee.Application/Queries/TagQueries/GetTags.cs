using Invee.Application.Models;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Queries.TagQueries
{
    public record GetTags : IRequest<OperationResult<List<Tag>>>;
}
