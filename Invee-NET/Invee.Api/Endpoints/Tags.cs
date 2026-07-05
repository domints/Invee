using Invee.Application.Commands.TagCommands;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Application.Queries.TagQueries;

namespace Invee.Api.Endpoints
{
    public static class Tags
    {
        public static RouteGroupBuilder MapTags(this RouteGroupBuilder group)
        {
            group.WithTags("Tags");
            group.MapQuery<GetTags, List<TagDto>>("/");
            group.MapBodyPostCommand<CreateTag, int>("/");
            group.MapParamDeleteCommand<DeleteTag>("/{id:int}");
            return group;
        }
    }
}
