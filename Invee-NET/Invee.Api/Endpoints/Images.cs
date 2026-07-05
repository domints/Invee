using Invee.Application.Models;
using Invee.Application.Queries.ImageQueries;

namespace Invee.Api.Endpoints
{
    public static class Images
    {
        public static RouteGroupBuilder MapImages(this RouteGroupBuilder group)
        {
            group.WithTags("Images");

            group.MapStreamQuery<GetImage>("/{id:int}").AllowAnonymous();

            return group;
        }
    }
}