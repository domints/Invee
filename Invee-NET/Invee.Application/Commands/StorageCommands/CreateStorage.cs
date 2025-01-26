using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.StorageCommands
{
    public record CreateStorage(string Name, int StorageTypeId, string? Slug, int? ParentId) : IRequest<OperationResult<int>>;
}