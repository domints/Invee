using Invee.Application.Queries.ShortLinkQueries;
using MediatR;

namespace Invee.Api.Endpoints
{
    public static class ShortLinks
    {
        public static WebApplication MapShortLinks(this WebApplication app, string shortHost, string canonicalBaseUrl)
        {
            var baseUrl = canonicalBaseUrl.TrimEnd('/');

            app.MapGet("/{slug}", async (string slug, IMediator mediator, CancellationToken ct) =>
            {
                var target = await mediator.Send(new ResolveShortLink(slug), ct);
                var url = target.Kind switch
                {
                    ShortLinkKind.Item => $"{baseUrl}/item/{target.Slug}",
                    ShortLinkKind.Storage => $"{baseUrl}/storage/{target.Slug}",
                    _ => baseUrl,
                };
                return Results.Redirect(url);
            })
            .RequireHost(shortHost)
            .AllowAnonymous()
            .ExcludeFromDescription();

            app.MapGet("/", () => Results.Redirect(baseUrl))
                .RequireHost(shortHost)
                .AllowAnonymous()
                .ExcludeFromDescription();

            return app;
        }
    }
}
