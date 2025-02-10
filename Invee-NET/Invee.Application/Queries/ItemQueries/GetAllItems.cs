using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.ItemQueries
{
    public record GetAllItems() : IRequest<OperationResult<List<ItemListEntry>>>;
}