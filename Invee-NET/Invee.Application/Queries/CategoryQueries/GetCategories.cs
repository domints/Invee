using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database.Model;
using MediatR;

namespace Invee.Application.Queries.CategoryQueries
{
    public record GetCategories() : IRequest<OperationResult<List<CategoryTreeResponse>>>;
}