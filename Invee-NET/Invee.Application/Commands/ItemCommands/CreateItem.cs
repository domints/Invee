using System;
using Invee.Application.Models;
using Invee.Data.Enums;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record CreateItem(string Name, int CategoryId, int StorageId, string? Slug, QuantityType QuantityType = QuantityType.None, decimal? Quantity = null, DateTime? ExpiresAt = null) : IRequest<OperationResult<int>>;
}