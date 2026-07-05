using System.Collections.Generic;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.ItemQueries
{
    public record GetExpiringItems() : IRequest<OperationResult<List<ItemListEntry>>>;
}
