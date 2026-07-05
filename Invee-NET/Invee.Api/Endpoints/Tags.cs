using Invee.Application.Commands.TagCommands;
using Invee.Application.Models;
using Invee.Application.Queries.TagQueries;
using Invee.Data.Database.Model;

namespace Invee.Api.Endpoints
{
    public static class Tags
    {
        public static RouteGroupBuilder MapTags(this RouteGroupBuilder group)
        {
            group.WithTags("Tags");
            group.MapQuery<GetTags, List<Tag>>("/");
            group.MapBodyPostCommand<CreateTag, int>("/");
            group.MapParamDeleteCommand<DeleteTag>("/{id:int}");
            return group;
        }
    }
}
