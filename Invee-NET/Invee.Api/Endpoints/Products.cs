using Invee.Application.Models.DTOs;
using Invee.Application.Queries.ProductQueries;

namespace Invee.Api.Endpoints
{
    public static class Products
    {
        public static RouteGroupBuilder MapProducts(this RouteGroupBuilder group)
        {
            group.WithTags("Products");
            group.MapQuery<LookupProductByBarcode, ExternalProductLookupDto>("/barcode/{barcode}").AllowAnonymous();
            return group;
        }
    }
}
