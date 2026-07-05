using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ImageCommands
{
    public record DeleteStorageImage(int Id, int ImageId)
        : ImageIdParameter(Id, ImageId), IRequest<OperationResult>;
}
