namespace Invee.Application.Models.DTOs
{
    public record ExternalProductLookupDto(
        string ProductName,
        List<string> Tags,
        string? FrontImageUrl
    );
}
