using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ImageCommands
{
    public record UploadItemImage(int Id, Stream Stream, string FileName, string ContentType)
        : IdParameter(Id), IRequest<OperationResult<int>>, IFileUploadCommand<IdParameter, UploadItemImage>
    {
        public static UploadItemImage Create(IdParameter p, Stream stream, string fileName, string contentType)
            => new(p.Id, stream, fileName, contentType);
    }
}
