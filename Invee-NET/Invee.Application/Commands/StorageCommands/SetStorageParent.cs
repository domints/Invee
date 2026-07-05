using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.StorageCommands
{
    public record SetStorageParent(int Id, int? ParentId) : IdParameter(Id), IRequest<OperationResult>;
}
