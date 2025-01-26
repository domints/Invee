using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.ItemCommands;

namespace Invee.Api.Endpoints
{
    public static class Items
    {
        public static RouteGroupBuilder MapItems(this RouteGroupBuilder group)
        {
            group.WithTags("Items");
            group.MapBodyPostCommand<CreateItem, int>("/");
            return group;
        }
    }
}