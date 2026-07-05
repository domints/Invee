using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.StorageTypeQueries
{
    public record GetStorageTypes : IRequest<OperationResult<List<StorageTypeDto>>>;
}
