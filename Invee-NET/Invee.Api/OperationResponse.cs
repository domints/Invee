using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Api.Models;
using Invee.Application.Models;
using Invee.Application.Models.DTOs;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Invee.Api
{

    public static class OperationResultConverter
    {
        public static Results<Ok, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>> ToResponse(this OperationResult result)
        {
            if (result is NotFoundOperationResult notFoundOperationResult)
                return TypedResults.NotFound(new NotFoundResponse(notFoundOperationResult.NotFoundEntity!));
            if (result is FailedOperationResult failedOperationResult)
                return TypedResults.BadRequest(new ErrorResponse(failedOperationResult.Errors));

            return TypedResults.Ok();
        } 

        public static Results<Ok<T>, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>> ToResponse<T>(this OperationResult<T> result)
        {
            if (result is NotFoundOperationResult<T> notFoundOperationResult)
                return TypedResults.NotFound(new NotFoundResponse(notFoundOperationResult.NotFoundEntity!));
            if (result is FailedOperationResult<T> failedOperationResult)
                return TypedResults.BadRequest(new ErrorResponse(failedOperationResult.Errors));

            return TypedResults.Ok(result.Data);
        } 
    }
}