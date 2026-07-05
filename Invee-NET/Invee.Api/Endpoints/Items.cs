using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.ImageCommands;
using Invee.Application.Commands.ItemCommands;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Application.Queries.ItemQueries;

namespace Invee.Api.Endpoints
{
    public static class Items
    {
        public static RouteGroupBuilder MapItems(this RouteGroupBuilder group)
        {
            group.WithTags("Items");
            group.MapBodyPostCommand<CreateItem, int>("/");
            group.MapQuery<GetAllItems, List<ItemListEntry>>("/");
            group.MapQuery<GetItem, ItemResponse>("/{id:int}").AllowAnonymous();
            group.MapBodyAndParamPutCommand<IdParameter, UpdateItem>("/{id:int}");
            group.MapBodyAndParamPutCommand<IdParameter, SetItemTags>("/{id:int}/tags");

            group.MapQuery<LookupItemByCode, int>("/byCode");
            group.MapQuery<GetExpiringItems, List<ItemListEntry>>("/expiring");
            group.MapBodyAndParamPostCommand<IdParameter, AddItemCode, int>("/{id:int}/codes");
            group.MapBodyAndParamPutCommand<ItemCodeIdParameter, UpdateItemCode>("/{id:int}/codes/{codeId:int}");
            group.MapParamDeleteCommand<DeleteItemCode>("/{id:int}/codes/{codeId:int}");

            group.MapBodyAndParamPostCommand<IdParameter, ReserveItem>("/{id:int}/reserve");
            group.MapBodyAndParamPostCommand<IdParameter, BorrowItem>("/{id:int}/borrow");
            group.MapParamPostCommand<BorrowReservation>("/{id:int}/borrowReservation");
            group.MapParamPostCommand<ReturnItem>("/{id:int}/return");
            group.MapParamPostCommand<CancelReservation>("/{id:int}/cancelReservation");

            group.MapFileUploadCommand<IdParameter, UploadItemImage, int>("/{id:int}/images");
            group.MapParamDeleteCommand<DeleteItemImage>("/{id:int}/images/{imageId:int}");
            group.MapBodyAndParamPutCommand<IdParameter, ReorderItemImages>("/{id:int}/images/order");

            return group;
        }
    }
}
