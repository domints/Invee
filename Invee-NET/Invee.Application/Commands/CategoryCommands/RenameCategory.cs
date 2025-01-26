using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Queries.CategoryCommands
{
    public record RenameCategory(int Id, string Name) : IdParameter(Id), IRequest<OperationResult>;
}