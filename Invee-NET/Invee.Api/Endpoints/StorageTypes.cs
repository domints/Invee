using Invee.Application.Commands.StorageTypeCommands;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Application.Queries.StorageTypeQueries;

namespace Invee.Api.Endpoints
{
    public static class StorageTypes
    {
        public static RouteGroupBuilder MapStorageTypes(this RouteGroupBuilder group)
        {
            group.WithTags("StorageTypes");
            group.MapQuery<GetStorageTypes, List<StorageTypeDto>>("/");
            group.MapBodyPostCommand<CreateStorageType, int>("/");
            group.MapBodyAndParamPutCommand<IdParameter, RenameStorageType>("/{id:int}");
            group.MapParamDeleteCommand<DeleteStorageType>("/{id:int}");
            return group;
        }
    }
}
