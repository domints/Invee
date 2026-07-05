using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Commands.TagCommands
{
    public class CreateTagHandler : IRequestHandler<CreateTag, OperationResult<int>>
    {
        private readonly InveeContext _db;

        public CreateTagHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<OperationResult<int>> Handle(CreateTag request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return OperationResult<int>.Fail(Errors.NameEmpty());
            var isDuplicate = _db.Tags.Any(t => t.Name == request.Name);
            if (isDuplicate)
                return OperationResult<int>.Fail(Errors.NameDuplicate(nameof(Tag)));

            var entity = new Tag
            {
                Name = request.Name
            };

            _db.Tags.Add(entity);
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success(entity.Id);
        }
    }
}
