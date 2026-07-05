using System;
using Invee.Application.Models;
using Invee.Data.Enums;
using MediatR;

namespace Invee.Application.Commands.ItemCommands
{
    public record UpdateItem(
        int Id,
        string Name,
        string? Slug,
        string? Note,
        int CategoryId,
        int StorageId,
        QuantityType QuantityType,
        decimal? Quantity,
        bool Broken,
        DateTime? ExpiresAt = null
    ) : IdParameter(Id), IRequest<OperationResult>;
}
