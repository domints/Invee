using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.TagQueries
{
    public record GetTags : IRequest<OperationResult<List<TagDto>>>;
}
