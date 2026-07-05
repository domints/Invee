using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.StorageTypeCommands;
using Invee.Application.Models;
using Invee.Application.Queries.StorageTypeQueries;
using Invee.Data.Database.Model;

namespace Invee.Api.Endpoints
{
    public static class StorageTypes
    {
        public static RouteGroupBuilder MapStorageTypes(this RouteGroupBuilder group)
        {
            group.WithTags("StorageTypes");
            group.MapQuery<GetStorageTypes, List<StorageType>>("/");
            group.MapBodyPostCommand<CreateStorageType, int>("/");
            group.MapBodyAndParamPutCommand<IdParameter, RenameStorageType>("/{id:int}");
            group.MapParamDeleteCommand<DeleteStorageType>("/{id:int}");
            return group;
        }
    }
}