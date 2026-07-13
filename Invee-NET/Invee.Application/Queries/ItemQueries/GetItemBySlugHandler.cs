using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ItemQueries
{
    public class GetItemBySlugHandler : IRequestHandler<GetItemBySlug, OperationResult<ItemResponse>>
    {
        private readonly InveeContext _db;
        private readonly IMediator _mediator;

        public GetItemBySlugHandler(InveeContext db, IMediator mediator)
        {
            _db = db;
            _mediator = mediator;
        }

        public async Task<OperationResult<ItemResponse>> Handle(GetItemBySlug request, CancellationToken cancellationToken)
        {
            var itemIdList = await _db.Items.Where(i => i.Slug == request.Slug).Select(i => i.Id).ToListAsync(cancellationToken: cancellationToken);
            if (itemIdList.Count == 0)
                return OperationResult<ItemResponse>.NotFound(nameof(Item));

            return await _mediator.Send(new GetItem(itemIdList[0]));
        }
    }
}
