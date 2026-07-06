using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries.ProductQueries
{
    public record LookupProductByBarcode(string Barcode) : IRequest<OperationResult<ExternalProductLookupDto>>;
}
