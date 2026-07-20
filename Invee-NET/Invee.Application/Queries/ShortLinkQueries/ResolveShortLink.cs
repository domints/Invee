using MediatR;

namespace Invee.Application.Queries.ShortLinkQueries
{
    public enum ShortLinkKind
    {
        None,
        Item,
        Storage,
    }

    public record ShortLinkTarget(ShortLinkKind Kind, string? Slug);

    public record ResolveShortLink(string Slug) : IRequest<ShortLinkTarget>;
}
