using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.ItemCommands
{
    public class SetItemTagsHandler : IRequestHandler<SetItemTags, OperationResult>
    {
        private readonly InveeContext _db;

        public SetItemTagsHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(SetItemTags request, CancellationToken cancellationToken)
        {
            var itemExists = await _db.Items.AnyAsync(i => i.Id == request.Id, cancellationToken);
            if (!itemExists)
                return OperationResult.NotFound(nameof(Item));

            var tagIds = request.TagIds.Distinct().ToList();
            if (tagIds.Count > 0)
            {
                var existingTagCount = await _db.Tags.CountAsync(t => tagIds.Contains(t.Id), cancellationToken);
                if (existingTagCount != tagIds.Count)
                    return OperationResult.Fail(Errors.InvalidTagIds());
            }

            var existing = await _db.ItemTags.Where(it => it.ItemId == request.Id).ToListAsync(cancellationToken);
            _db.ItemTags.RemoveRange(existing);

            foreach (var tagId in tagIds)
            {
                _db.ItemTags.Add(new ItemTag
                {
                    ItemId = request.Id,
                    TagId = tagId
                });
            }

            await _db.SaveChangesAsync(cancellationToken);
            return OperationResult.Success();
        }
    }
}
