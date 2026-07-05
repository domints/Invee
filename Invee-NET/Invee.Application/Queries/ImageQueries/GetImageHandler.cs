using Invee.Application.Models;
using Invee.Application.Services;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ImageQueries
{
    public class GetImageHandler : IRequestHandler<GetImage, OperationResult<StreamResult>>
    {
        private readonly InveeContext _db;
        private readonly IImageStore _imageStore;

        public GetImageHandler(InveeContext db, IImageStore imageStore)
        {
            _db = db;
            _imageStore = imageStore;
        }

        public async Task<OperationResult<StreamResult>> Handle(GetImage request, CancellationToken cancellationToken)
        {
            var image = await _db.Images.FirstOrDefaultAsync(i => i.Id == request.Id, cancellationToken);
            if (image == null)
                return OperationResult<StreamResult>.NotFound(nameof(Data.Database.Model.Image));

            var (stream, contentType) = await _imageStore.RetrieveAsync(image.StoredPath, cancellationToken);
            return OperationResult.Success(new StreamResult(stream, contentType));
        }
    }
}
