using Invee.Application.Models;
using Invee.Application.Services;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ImageCommands
{
    public class DeleteStorageImageHandler : IRequestHandler<DeleteStorageImage, OperationResult>
    {
        private readonly InveeContext _db;
        private readonly IImageStore _imageStore;

        public DeleteStorageImageHandler(InveeContext db, IImageStore imageStore)
        {
            _db = db;
            _imageStore = imageStore;
        }

        public async Task<OperationResult> Handle(DeleteStorageImage request, CancellationToken cancellationToken)
        {
            var storageImage = await _db.StorageImages
                .Include(si => si.Image)
                .FirstOrDefaultAsync(si => si.StorageId == request.Id && si.ImageId == request.ImageId, cancellationToken);

            if (storageImage == null)
                return OperationResult.NotFound(nameof(StorageImage));

            var image = storageImage.Image!;
            _db.StorageImages.Remove(storageImage);

            var isShared = await _db.ItemImages.AnyAsync(ii => ii.ImageId == image.Id, cancellationToken)
                || await _db.StorageImages.AnyAsync(si => si.ImageId == image.Id && si.StorageId != request.Id, cancellationToken);

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
