using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.StorageQueries
{
    public class GetStorageBySlugHandler : IRequestHandler<GetStorageBySlug, OperationResult<StorageItemsResponse>>
    {
        private readonly InveeContext _db;
        private readonly IMediator _mediator;

        public GetStorageBySlugHandler(InveeContext db, IMediator mediator)
        {
            _db = db;
            _mediator = mediator;
        }

        public async Task<OperationResult<StorageItemsResponse>> Handle(GetStorageBySlug request, CancellationToken cancellationToken)
        {
            var storageIdList = await _db.Storages.Where(s => s.Slug == request.Slug).Select(s => s.Id).ToListAsync(cancellationToken: cancellationToken);
            if (storageIdList.Count == 0)
                return OperationResult<StorageItemsResponse>.NotFound();

            return await _mediator.Send(new GetStorage(storageIdList[0]));
        }
    }
}