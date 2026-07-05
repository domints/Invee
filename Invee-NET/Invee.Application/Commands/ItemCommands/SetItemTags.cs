using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record SetItemTags(int Id, List<int> TagIds) : IdParameter(Id), IRequest<OperationResult>;
}
