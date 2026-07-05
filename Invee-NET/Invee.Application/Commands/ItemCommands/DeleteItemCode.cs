using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record DeleteItemCode(int Id, int CodeId) : IRequest<OperationResult>;
}
