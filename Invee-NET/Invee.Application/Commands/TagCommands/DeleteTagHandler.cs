using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Commands.TagCommands
{
    public class DeleteTagHandler : IRequestHandler<DeleteTag, OperationResult>
    {
        private readonly InveeContext _db;

        public DeleteTagHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult> Handle(DeleteTag request, CancellationToken cancellationToken)
        {
            var entity = await _db.Tags.FirstOrDefaultAsync(t => t.Id == request.Id, cancellationToken);
            if (entity == null)
                return OperationResult.NotFound(nameof(Tag));

            _db.Tags.Remove(entity);
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success();
        }
    }
}
