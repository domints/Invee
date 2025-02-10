using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record BorrowItem(int Id, string BorrowerName, DateTime ExpectedReturn, bool Incomplete, string? Comment) : IdParameter(Id), IRequest<OperationResult>;
}