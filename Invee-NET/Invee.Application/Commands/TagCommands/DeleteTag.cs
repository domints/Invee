using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.TagCommands
{
    public record DeleteTag(int Id) : IRequest<OperationResult>;
}
