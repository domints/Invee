using Invee.Application.Models;
using Invee.Data.Enums;
using MediatR;

namespace Invee.Application.Queries.ItemQueries
{
    public record LookupItemByCode(string Contents, CodeType? CodeType) : IRequest<OperationResult<int>>;
}
