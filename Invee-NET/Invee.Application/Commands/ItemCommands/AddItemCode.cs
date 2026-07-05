using Invee.Application.Models;
using Invee.Data.Enums;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record AddItemCode(int Id, CodeType CodeType, string Contents) : IdParameter(Id), IRequest<OperationResult<int>>;
}
