using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Api.Models;
using Invee.Application.Models;
using Invee.Application.Queries;
using MediatR;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace Invee.Api.Endpoints
{
    public static class Api
    {
        public static RouteGroupBuilder MapApis(this RouteGroupBuilder group)
        {
            group.MapGet("/auth", (string redirect) => Results.Redirect(redirect));
            group.MapGet("/user", (HttpContext context, IMediator mediator, CancellationToken cancellationToken) => mediator.Send(new UserInfo(context.User), cancellationToken));
            group.MapGroup("/categories").MapCategories();
            group.MapGroup("/storageTypes").MapStorageTypes();
            group.MapGroup("/storages").MapStorages();
            group.MapGroup("/items").MapItems();

            return group;
        }

        /// <summary>
        /// Maps GET request using route/query params and sends it as MediatR query
        /// </summary>
        /// <typeparam name="T">Type of query</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Query result</returns>
        public static RouteGroupBuilder MapQuery<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : IRequest<OperationResult<TResponse>>
        {
            group.MapGet(path, ParametersDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps POST request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyPostCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPost(path, BodyDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PUT request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyPutCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPut(path, BodyDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PATCH request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyPatchCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPatch(path, BodyDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps DELETE request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyDeleteCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapDelete(path, BodyDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps POST request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamPostCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPost(path, ParametersDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PUT request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamPutCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPut(path, ParametersDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PATCH request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamPatchCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPatch(path, ParametersDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps DELETE request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamDeleteCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapDelete(path, ParametersDelegate<T>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps POST request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamPostCommand<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapPost(path, ParametersAndBodyDelegate<TParams, TBody>).WithName(GetEndpointName<TBody>());

            return group;
        }

        /// <summary>
        /// Maps PUT request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamPutCommand<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapPut(path, ParametersAndBodyDelegate<TParams, TBody>).WithName(GetEndpointName<TBody>());

            return group;
        }

        /// <summary>
        /// Maps PATCH request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamPatchCommand<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapPatch(path, ParametersAndBodyDelegate<TParams, TBody>).WithName(GetEndpointName<TBody>());

            return group;
        }

        /// <summary>
        /// Maps DELETE request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamDeleteCommand<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapDelete(path, ParametersAndBodyDelegate<TParams, TBody>).WithName(GetEndpointName<TBody>());

            return group;
        }

        #region Response endpoints

        /// <summary>
        /// Maps POST request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyPostCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPost(path, BodyDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PUT request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyPutCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPut(path, BodyDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PATCH request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyPatchCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPatch(path, BodyDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps DELETE request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyDeleteCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapDelete(path, BodyDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps POST request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamPostCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPost(path, ParametersDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PUT request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamPutCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPut(path, ParametersDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps PATCH request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamPatchCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPatch(path, ParametersDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps DELETE request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapParamDeleteCommand<T,TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapDelete(path, ParametersDelegate<T, TResponse>).WithName(GetEndpointName<T>());

            return group;
        }

        /// <summary>
        /// Maps POST request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamPostCommand<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapPost(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>).WithName(GetEndpointName<TBody>());

            return group;
        }

        /// <summary>
        /// Maps PUT request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamPutCommand<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapPut(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>).WithName(GetEndpointName<TBody>());

            return group;
        }

        /// <summary>
        /// Maps PATCH request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamPatchCommand<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapPatch(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>).WithName(GetEndpointName<TBody>());

            return group;
        }

        /// <summary>
        /// Maps DELETE request using route/query params and body, merges them and sends body object as MediatR command
        /// </summary>
        /// <typeparam name="TParams">Type of params</typeparam>
        /// <typeparam name="TBody">Type of body, also type of MediatR IRequest</typeparam>
        /// <typeparam name="TResponse">Type of response</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapBodyAndParamDeleteCommand<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapDelete(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>).WithName(GetEndpointName<TBody>());

            return group;
        }

        #endregion

        private static async Task<Results<Ok, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>>> ParametersDelegate<TParams>([AsParameters] TParams parameters, IMediator mediator, CancellationToken cancellationToken)
            where TParams : IRequest<OperationResult>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>>> BodyDelegate<TBody>([FromBody] TBody parameters, IMediator mediator, CancellationToken cancellationToken)
            where TBody : IRequest<OperationResult>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>>> ParametersAndBodyDelegate<TParams, TBody>([AsParameters] TParams parameters, [FromBody] TBody body, IMediator mediator, CancellationToken cancellationToken)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            var paramProps = typeof(TParams).GetProperties();
                foreach (var p in paramProps)
                {
                    p.SetValue(body, p.GetValue(parameters));
                }

                var result = await mediator.Send(body, cancellationToken);
                
                return result.ToResponse();
        }

        private static async Task<Results<Ok<TResponse>, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>>> ParametersDelegate<TParams, TResponse>([AsParameters] TParams parameters, IMediator mediator, CancellationToken cancellationToken)
            where TParams : IRequest<OperationResult<TResponse>>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok<TResponse>, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>>> BodyDelegate<TBody, TResponse>([FromBody] TBody parameters, IMediator mediator, CancellationToken cancellationToken)
            where TBody : IRequest<OperationResult<TResponse>>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok<TResponse>, BadRequest<ErrorResponse>, NotFound<NotFoundResponse>>> ParametersAndBodyDelegate<TParams, TBody, TResponse>([AsParameters] TParams parameters, [FromBody] TBody body, IMediator mediator, CancellationToken cancellationToken)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            var paramProps = typeof(TParams).GetProperties();
                foreach (var p in paramProps)
                {
                    p.SetValue(body, p.GetValue(parameters));
                }

                var result = await mediator.Send(body, cancellationToken);
                
                return result.ToResponse();
        }

        private static string GetEndpointName<TRequest>()
        {
            return typeof(TRequest).Name;
        }
    }
}