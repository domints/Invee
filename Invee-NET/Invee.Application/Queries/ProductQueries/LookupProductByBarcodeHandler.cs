using System.Text.Json;
using System.Text.Json.Serialization;
using Invee.Application.Consts;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Data.Database;
using Invee.Data.Database.Model;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ProductQueries
{
    public class LookupProductByBarcodeHandler : IRequestHandler<LookupProductByBarcode, OperationResult<ExternalProductLookupDto>>
    {
        private readonly InveeContext _db;
        private readonly IHttpClientFactory _httpClientFactory;

        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public LookupProductByBarcodeHandler(InveeContext db, IHttpClientFactory httpClientFactory)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
        }

        public async Task<OperationResult<ExternalProductLookupDto>> Handle(LookupProductByBarcode request, CancellationToken cancellationToken)
        {
            var cached = await _db.CachedProducts
                .FirstOrDefaultAsync(p => p.Barcode == request.Barcode, cancellationToken);

            if (cached != null)
                return OperationResult.Success(new ExternalProductLookupDto(cached.ProductName, cached.Tags, cached.FrontImageUrl));

            var client = _httpClientFactory.CreateClient("OpenFoodFacts");
            var response = await client.GetAsync($"api/v0/product/{request.Barcode}.json", cancellationToken);

            if (!response.IsSuccessStatusCode)
                return OperationResult<ExternalProductLookupDto>.NotFound("Product");

            var rawJson = await response.Content.ReadAsStringAsync(cancellationToken);
            var offResponse = JsonSerializer.Deserialize<OpenFoodFactsResponse>(rawJson, _jsonOptions);

            if (offResponse?.Status != 1 || offResponse.Product == null)
                return OperationResult<ExternalProductLookupDto>.NotFound("Product");

            var product = offResponse.Product;
            var entry = new CachedProduct
            {
                Barcode = request.Barcode,
                ProductName = product.ProductName ?? string.Empty,
                Tags = product.Keywords ?? [],
                FrontImageUrl = product.ImageFrontUrl,
                DataSource = ProductDataSources.OpenFoodFacts,
                RawJson = rawJson,
                CachedAt = DateTime.UtcNow
            };

            _db.CachedProducts.Add(entry);
            await _db.SaveChangesAsync(cancellationToken);

            return OperationResult.Success(new ExternalProductLookupDto(entry.ProductName, entry.Tags, entry.FrontImageUrl));
        }

        private class OpenFoodFactsResponse
        {
            [JsonPropertyName("status")]
            public int Status { get; set; }

            [JsonPropertyName("product")]
            public OpenFoodFactsProduct? Product { get; set; }
        }

        private class OpenFoodFactsProduct
        {
            [JsonPropertyName("product_name")]
            public string? ProductName { get; set; }

            [JsonPropertyName("_keywords")]
            public List<string>? Keywords { get; set; }

            [JsonPropertyName("image_front_url")]
            public string? ImageFrontUrl { get; set; }
        }
    }
}
