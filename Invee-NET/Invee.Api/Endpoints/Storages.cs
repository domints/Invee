using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.ImageCommands;
using Invee.Application.Commands.StorageCommands;
using Invee.Application.Models;
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
            group.MapBodyAndParamPutCommand<IdParameter, UpdateStorage>("/{id:int}");
            group.MapParamDeleteCommand<DeleteStorage>("/{id:int}");
            group.MapBodyAndParamPostCommand<IdParameter, SetStorageParent>("/{id:int}/setParent");

            group.MapFileUploadCommand<IdParameter, UploadStorageImage, int>("/{id:int}/images");
            group.MapParamDeleteCommand<DeleteStorageImage>("/{id:int}/images/{imageId:int}");
            group.MapBodyAndParamPutCommand<IdParameter, ReorderStorageImages>("/{id:int}/images/order");

            return group;
        }
    }
}