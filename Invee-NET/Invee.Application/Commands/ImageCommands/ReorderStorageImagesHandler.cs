using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ImageCommands
{
    public class ReorderStorageImagesHandler : IRequestHandler<ReorderStorageImages, OperationResult>
    {
        private readonly InveeContext _db;

        public ReorderStorageImagesHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(ReorderStorageImages request, CancellationToken cancellationToken)
        {
            var storageImages = await _db.StorageImages
                .Where(si => si.StorageId == request.Id)
                .ToListAsync(cancellationToken);

            var imageIds = storageImages.Select(si => si.ImageId).ToHashSet();
            if (!request.OrderedImageIds.All(id => imageIds.Contains(id)))
                return OperationResult.Fail(Errors.InvalidImageIds());

            for (int i = 0; i < request.OrderedImageIds.Count; i++)
            {
                var imageId = request.OrderedImageIds[i];
                var storageImage = storageImages.First(si => si.ImageId == imageId);
                storageImage.Order = i;
            }

            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}
