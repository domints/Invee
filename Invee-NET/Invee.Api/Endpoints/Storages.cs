using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.StorageCommands;
using Invee.Application.Models.DTOs;
using Invee.Application.Queries.StorageQueries;

namespace Invee.Api.Endpoints
{
    public static class Storages
    {
        public static RouteGroupBuilder MapStorages(this RouteGroupBuilder group)
        {
            group.WithTags("Storages");
            group.MapQuery<GetStorages, List<StorageTreeResponse>>("/");
            group.MapQuery<GetRootStorage, List<StorageListEntry>>("/root");
            group.MapQuery<GetStorage, StorageItemsResponse>("/{id:int}");
            group.MapQuery<GetStorageBySlug, StorageItemsResponse>("/slug/{slug:regex(^[a-z0-9_-]+$)}");
            group.MapBodyPostCommand<CreateStorage, int>("/");
            return group;
        }
    }
}