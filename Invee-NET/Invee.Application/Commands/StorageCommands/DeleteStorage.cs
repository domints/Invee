using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.StorageCommands
{
    public record DeleteStorage(int Id) : IRequest<OperationResult>;
}
