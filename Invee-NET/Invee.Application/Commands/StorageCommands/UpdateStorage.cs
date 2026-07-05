using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.StorageCommands
{
    public record UpdateStorage(int Id, string Name, int StorageTypeId) : IdParameter(Id), IRequest<OperationResult>;
}
