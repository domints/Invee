using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Queries.CategoryCommands
{
    public record DeleteCategory(int Id) : IRequest<OperationResult>;
}