using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Queries.StorageTypeQueries
{
    public record GetStorageTypes : IRequest<OperationResult<List<StorageType>>>;
}