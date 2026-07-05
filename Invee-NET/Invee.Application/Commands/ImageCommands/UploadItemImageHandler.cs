using Invee.Application.Models;
using Invee.Application.Services;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ImageCommands
{
    public class UploadItemImageHandler : IRequestHandler<UploadItemImage, OperationResult<int>>
    {
        private readonly InveeContext _db;
        private readonly IImageStore _imageStore;

        public UploadItemImageHandler(InveeContext db, IImageStore imageStore)
        {
            _db = db;
            _imageStore = imageStore;
        }

        public async Task<OperationResult<int>> Handle(UploadItemImage request, CancellationToken cancellationToken)
        {
            var itemExists = await _db.Items.AnyAsync(i => i.Id == request.Id, cancellationToken);
            if (!itemExists)
                return OperationResult<int>.NotFound(nameof(Item));

            var storedPath = await _imageStore.StoreAsync(request.Stream, request.FileName, request.ContentType, cancellationToken);

            var image = new Image
            {
                FileName = request.FileName,
                ContentType = request.ContentType,
                StoredPath = storedPath,
                CreatedAt = DateTime.UtcNow
            };
            _db.Images.Add(image);
            await _db.SaveChangesAsync(cancellationToken);

            var maxOrder = await _db.ItemImages
                .Where(ii => ii.ItemId == request.Id)
                .Select(ii => (int?)ii.Order)
                .MaxAsync(cancellationToken) ?? -1;

            _db.ItemImages.Add(new ItemImage
            {
                ItemId = request.Id,
                ImageId = image.Id,
                Order = maxOrder + 1
            });
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success(image.Id);
        }
    }
}
