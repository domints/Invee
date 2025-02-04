using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Commands.CategoryCommands;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Invee.Application.Queries.CategoryQueries;
using Invee.Data.Database.Model;

namespace Invee.Api.Endpoints
{
    public static class Categories
    {
        public static RouteGroupBuilder MapCategories(this RouteGroupBuilder group)
        {
            group.WithTags("Categories");
            group.MapQuery<GetCategoryTree, List<CategoryTreeResponse>>("/");//.WithName("GetCategoryTree");
            group.MapQuery<GetCategory, CategoryDTO>("/{id:int}");//.WithName("GetCategory");
            group.MapBodyPostCommand<CreateCategory, int>("/");//.WithName("CreateCategory");
            group.MapParamDeleteCommand<DeleteCategory>("/{id:int}");//.WithName("DeleteCategory");
            group.MapBodyAndParamPutCommand<IdParameter, RenameCategory>("/{id:int}");//.WithName("RenameCategory");
            group.MapParamPostCommand<SetCategoryParent>("/{id:int}/setParent/{parentId:int?}");
            return group;
        }
    }
}