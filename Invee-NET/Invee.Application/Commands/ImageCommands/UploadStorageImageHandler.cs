using Invee.Application.Models;
using Invee.Application.Services;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ImageCommands
{
    public class UploadStorageImageHandler : IRequestHandler<UploadStorageImage, OperationResult<int>>
    {
        private readonly InveeContext _db;
        private readonly IImageStore _imageStore;

        public UploadStorageImageHandler(InveeContext db, IImageStore imageStore)
        {
            _db = db;
            _imageStore = imageStore;
        }

        public async Task<OperationResult<int>> Handle(UploadStorageImage request, CancellationToken cancellationToken)
        {
            var storageExists = await _db.Storages.AnyAsync(s => s.Id == request.Id, cancellationToken);
            if (!storageExists)
                return OperationResult<int>.NotFound(nameof(Storage));

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

            var maxOrder = await _db.StorageImages
                .Where(si => si.StorageId == request.Id)
                .Select(si => (int?)si.Order)
                .MaxAsync(cancellationToken) ?? -1;

            _db.StorageImages.Add(new StorageImage
            {
                StorageId = request.Id,
                ImageId = image.Id,
                Order = maxOrder + 1
            });
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success(image.Id);
        }
    }
}
