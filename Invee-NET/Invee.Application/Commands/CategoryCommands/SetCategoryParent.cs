using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.CategoryCommands
{
    public record SetCategoryParent(int Id, int? ParentId) : IdParameter(Id), IRequest<OperationResult>;
}