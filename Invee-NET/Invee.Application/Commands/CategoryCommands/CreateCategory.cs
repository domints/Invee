using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.CategoryCommands
{
    public record CreateCategory(string Name, int? ParentId, string? Slug) : IRequest<OperationResult<int>>;
}