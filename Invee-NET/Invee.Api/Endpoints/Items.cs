using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
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
            group.MapQuery<GetItem, ItemResponse>("/{id:int}");

            group.MapBodyAndParamPostCommand<IdParameter, ReserveItem>("/{id:int}/reserve");
            group.MapBodyAndParamPostCommand<IdParameter, BorrowItem>("/{id:int}/borrow");
            group.MapParamPostCommand<BorrowReservation>("/{id:int}/borrowReservation");
            group.MapParamPostCommand<ReturnItem>("/{id:int}/return");
            group.MapParamPostCommand<CancelReservation>("/{id:int}/cancelReservation");
            return group;
        }
    }
}