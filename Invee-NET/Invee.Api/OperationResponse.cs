using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Invee.Api
{
    public class OperationResponse
    {
        public List<string>? Errors { get; set; }
    }

    public class OperationResponse<T> : OperationResponse
    {
        public T? Data { get; set; }
    }

    public static class OperationResponseConverter
    {
        public static Results<Ok<OperationResponse>, BadRequest<OperationResponse>, NotFound<OperationResponse>> ToResponse(this OperationResult result)
        {
            if (result.IsNotFound)
            {
                return TypedResults.NotFound(new OperationResponse());
            }
            if (!result.IsOk)
            {
                return TypedResults.BadRequest(new OperationResponse());
            }

            return TypedResults.Ok(new OperationResponse());
        }

        public static Results<Ok<OperationResponse<T>>, BadRequest<OperationResponse<T>>, NotFound<OperationResponse<T>>> ToResponse<T>(this OperationResult<T> result)
        {
            if (result.IsNotFound)
            {
                return TypedResults.NotFound(new OperationResponse<T> { Data = result.Data });
            }
            if (!result.IsOk)
            {
                return TypedResults.BadRequest(new OperationResponse<T> { Data = result.Data});
            }

            return TypedResults.Ok(new OperationResponse<T> { Data = result.Data });
        }
    }
}