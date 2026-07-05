using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.TagCommands
{
    public record CreateTag(string Name) : IRequest<OperationResult<int>>;
}
