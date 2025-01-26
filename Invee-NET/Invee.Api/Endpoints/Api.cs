using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models;
using MediatR;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace Invee.Api.Endpoints
{
    public static class Api
    {
        public static RouteGroupBuilder MapApis(this RouteGroupBuilder group)
        {
            group.MapGet("/XD", (HttpContext cx) => {
                Results.Ok("XDDD");
            });
            group.MapGroup("/categories").MapCategories();

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
            group.MapGet(path, ParametersDelegate<T, TResponse>);

            return group;
        }

        /// <summary>
        /// Maps POST request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapPostCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPost(path, BodyDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps PUT request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapPutCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPut(path, BodyDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps PATCH request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapPatchCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPatch(path, BodyDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps DELETE request using body and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of body</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapDeleteCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapDelete(path, BodyDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps POST request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapPostParamCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPost(path, ParametersDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps PUT request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapPutParamCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPut(path, ParametersDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps PATCH request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapPatchParamCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapPatch(path, ParametersDelegate<T>);

            return group;
        }

        /// <summary>
        /// Maps DELETE request using route/query params and sends it as MediatR command
        /// </summary>
        /// <typeparam name="T">Type of params</typeparam>
        /// <param name="group">Route Group</param>
        /// <param name="path">Resource URL</param>
        /// <returns>Command result</returns>
        public static RouteGroupBuilder MapDeleteParamCommand<T>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult>
        {
            group.MapDelete(path, ParametersDelegate<T>);

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
        public static RouteGroupBuilder MapPostCommandWithParams<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapPost(path, ParametersAndBodyDelegate<TParams, TBody>);

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
        public static RouteGroupBuilder MapPutCommandWithParams<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapPut(path, ParametersAndBodyDelegate<TParams, TBody>);

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
        public static RouteGroupBuilder MapPatchCommandWithParams<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapPatch(path, ParametersAndBodyDelegate<TParams, TBody>);

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
        public static RouteGroupBuilder MapDeleteCommandWithParams<TParams, TBody>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult>
            where TParams : class
        {
            group.MapDelete(path, ParametersAndBodyDelegate<TParams, TBody>);

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
        public static RouteGroupBuilder MapPostCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPost(path, BodyDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapPutCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPut(path, BodyDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapPatchCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPatch(path, BodyDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapDeleteCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapDelete(path, BodyDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapPostParamCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPost(path, ParametersDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapPutParamCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPut(path, ParametersDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapPatchParamCommand<T, TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapPatch(path, ParametersDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapDeleteParamCommand<T,TResponse>(this RouteGroupBuilder group, string path)
            where T : class, IRequest<OperationResult<TResponse>>
        {
            group.MapDelete(path, ParametersDelegate<T, TResponse>);

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
        public static RouteGroupBuilder MapPostCommandWithParams<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapPost(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>);

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
        public static RouteGroupBuilder MapPutCommandWithParams<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapPut(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>);

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
        public static RouteGroupBuilder MapPatchCommandWithParams<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapPatch(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>);

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
        public static RouteGroupBuilder MapDeleteCommandWithParams<TParams, TBody, TResponse>(this RouteGroupBuilder group, string path)
            where TBody : class, TParams, IRequest<OperationResult<TResponse>>
            where TParams : class
        {
            group.MapDelete(path, ParametersAndBodyDelegate<TParams, TBody, TResponse>);

            return group;
        }

        #endregion

        private static async Task<Results<Ok<OperationResponse>, BadRequest<OperationResponse>, NotFound<OperationResponse>>> ParametersDelegate<TParams>([AsParameters] TParams parameters, IMediator mediator, CancellationToken cancellationToken)
            where TParams : IRequest<OperationResult>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok<OperationResponse>, BadRequest<OperationResponse>, NotFound<OperationResponse>>> BodyDelegate<TBody>([FromBody] TBody parameters, IMediator mediator, CancellationToken cancellationToken)
            where TBody : IRequest<OperationResult>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok<OperationResponse>, BadRequest<OperationResponse>, NotFound<OperationResponse>>> ParametersAndBodyDelegate<TParams, TBody>([AsParameters] TParams parameters, [FromBody] TBody body, IMediator mediator, CancellationToken cancellationToken)
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

        private static async Task<Results<Ok<OperationResponse<TResponse>>, BadRequest<OperationResponse<TResponse>>, NotFound<OperationResponse<TResponse>>>> ParametersDelegate<TParams, TResponse>([AsParameters] TParams parameters, IMediator mediator, CancellationToken cancellationToken)
            where TParams : IRequest<OperationResult<TResponse>>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok<OperationResponse<TResponse>>, BadRequest<OperationResponse<TResponse>>, NotFound<OperationResponse<TResponse>>>> BodyDelegate<TBody, TResponse>([FromBody] TBody parameters, IMediator mediator, CancellationToken cancellationToken)
            where TBody : IRequest<OperationResult<TResponse>>
        {
            var result = await mediator.Send(parameters, cancellationToken);
                
            return result.ToResponse();
        }

        private static async Task<Results<Ok<OperationResponse<TResponse>>, BadRequest<OperationResponse<TResponse>>, NotFound<OperationResponse<TResponse>>>> ParametersAndBodyDelegate<TParams, TBody, TResponse>([AsParameters] TParams parameters, [FromBody] TBody body, IMediator mediator, CancellationToken cancellationToken)
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
    }
}