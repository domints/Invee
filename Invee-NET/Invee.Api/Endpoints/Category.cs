using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.CategoryCommands;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Application.Queries.CategoryQueries;

namespace Invee.Api.Endpoints
{
    public static class Category
    {
        public static RouteGroupBuilder MapCategories(this RouteGroupBuilder group)
        {
            group.WithTags("Categories");
            group.MapQuery<GetCategories, List<CategoryTreeResponse>>("/");
            group.MapQuery<GetCategory, Data.Database.Model.Category>("/{id:int}");
            group.MapBodyPostCommand<CreateCategory, int>("/");
            group.MapParamDeleteCommand<DeleteCategory>("/{id:int}");
            group.MapBodyAndParamPutCommand<IdParameter, RenameCategory>("/{id:int}");
            group.MapParamPostCommand<SetCategoryParent>("/{id:int}/setParent/{parentId:int?}");
            return group;
        }
    }
}