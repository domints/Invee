using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ImageCommands
{
    public record ReorderStorageImages(int Id, List<int> OrderedImageIds)
        : IdParameter(Id), IRequest<OperationResult>;
}
