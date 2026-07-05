using Invee.Application.Models;
using Invee.Data.Enums;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record UpdateItemCode(int Id, int CodeId, CodeType CodeType, string Contents) : ItemCodeIdParameter(Id, CodeId), IRequest<OperationResult>;
}
