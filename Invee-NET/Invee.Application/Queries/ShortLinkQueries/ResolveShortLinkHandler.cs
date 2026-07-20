using System.Text.RegularExpressions;
using Invee.Data.Database;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Invee.Application.Queries.ShortLinkQueries
{
    public partial class ResolveShortLinkHandler : IRequestHandler<ResolveShortLink, ShortLinkTarget>
    {
        private readonly InveeContext _db;

        public ResolveShortLinkHandler(InveeContext db)
        {
            _db = db;
        }

        public async Task<ShortLinkTarget> Handle(ResolveShortLink request, CancellationToken cancellationToken)
        {
            var slug = request.Slug?.Trim().ToLowerInvariant();

            if (string.IsNullOrEmpty(slug) || !SlugRegex().IsMatch(slug))
                return new ShortLinkTarget(ShortLinkKind.None, null);

            if (await _db.Items.AnyAsync(i => i.Slug == slug, cancellationToken))
                return new ShortLinkTarget(ShortLinkKind.Item, slug);

            if (await _db.Storages.AnyAsync(s => s.Slug == slug, cancellationToken))
                return new ShortLinkTarget(ShortLinkKind.Storage, slug);

            return new ShortLinkTarget(ShortLinkKind.None, null);
        }

        [GeneratedRegex("^[a-z0-9_-]+$")]
        private static partial Regex SlugRegex();
    }
}
