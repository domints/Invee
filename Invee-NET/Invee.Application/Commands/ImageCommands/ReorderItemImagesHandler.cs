using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ImageCommands
{
    public class ReorderItemImagesHandler : IRequestHandler<ReorderItemImages, OperationResult>
    {
        private readonly InveeContext _db;

        public ReorderItemImagesHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(ReorderItemImages request, CancellationToken cancellationToken)
        {
            var itemImages = await _db.ItemImages
                .Where(ii => ii.ItemId == request.Id)
                .ToListAsync(cancellationToken);

            var imageIds = itemImages.Select(ii => ii.ImageId).ToHashSet();
            if (!request.OrderedImageIds.All(id => imageIds.Contains(id)))
                return OperationResult.Fail(Errors.InvalidImageIds());

            for (int i = 0; i < request.OrderedImageIds.Count; i++)
            {
                var imageId = request.OrderedImageIds[i];
                var itemImage = itemImages.First(ii => ii.ImageId == imageId);
                itemImage.Order = i;
            }

            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}
