using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.StorageQueries
{
    public record GetStorages : IRequest<OperationResult<List<StorageTreeResponse>>>;
}