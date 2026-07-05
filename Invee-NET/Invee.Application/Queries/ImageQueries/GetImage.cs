using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Queries.ImageQueries
{
    public record GetImage(int Id) : IRequest<OperationResult<StreamResult>>;
}
