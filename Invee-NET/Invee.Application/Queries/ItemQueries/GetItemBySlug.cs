using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.ItemQueries
{
    public record GetItemBySlug(string Slug) : IRequest<OperationResult<ItemResponse>>;
}
