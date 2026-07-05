using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ImageCommands
{
    public record ReorderItemImages(int Id, List<int> OrderedImageIds)
        : IdParameter(Id), IRequest<OperationResult>;
}
