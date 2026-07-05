using Invee.Application.Models;
using Invee.Application.Services;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ImageCommands
{
    public class DeleteItemImageHandler : IRequestHandler<DeleteItemImage, OperationResult>
    {
        private readonly InveeContext _db;
        private readonly IImageStore _imageStore;

        public DeleteItemImageHandler(InveeContext db, IImageStore imageStore)
        {
            _db = db;
            _imageStore = imageStore;
        }

        public async Task<OperationResult> Handle(DeleteItemImage request, CancellationToken cancellationToken)
        {
            var itemImage = await _db.ItemImages
                .Include(ii => ii.Image)
                .FirstOrDefaultAsync(ii => ii.ItemId == request.Id && ii.ImageId == request.ImageId, cancellationToken);

            if (itemImage == null)
                return OperationResult.NotFound(nameof(ItemImage));

            var image = itemImage.Image!;
            _db.ItemImages.Remove(itemImage);

            var isShared = await _db.StorageImages.AnyAsync(si => si.ImageId == image.Id, cancellationToken)
                || await _db.ItemImages.AnyAsync(ii => ii.ImageId == image.Id && ii.ItemId != request.Id, cancellationToken);

            if (!isShared)
            {
                _db.Images.Remove(image);
                await _db.SaveChangesAsync(cancellationToken);
                await _imageStore.DeleteAsync(image.StoredPath, cancellationToken);
            }
            else
            {
                await _db.SaveChangesAsync(cancellationToken);
            }

            return OperationResult.Success();
        }
    }
}
