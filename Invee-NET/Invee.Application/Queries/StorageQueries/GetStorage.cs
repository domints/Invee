using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.StorageQueries
{
    public record GetStorage(int Id) : IRequest<OperationResult<StorageItemsResponse>>;
}