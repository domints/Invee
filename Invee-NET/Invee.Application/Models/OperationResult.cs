using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models.DTOs;

namespace Invee.Application.Models
{
    public class OperationResult
    {
        public bool IsOk { get; set; } = true;
        public static OperationResult Success() => new() { IsOk = true };
        public static FailedOperationResult Fail(params Error[] errors) => new() { Errors = errors.ToList() };
        public static NotFoundOperationResult NotFound(string entityName) => new(entityName);

        public static OperationResult<T> Success<T>(T data) => new() { IsOk = true, Data = data };
    }

    public class NotFoundOperationResult : OperationResult
    {
        public NotFoundOperationResult(string notFoundEntity)
        {
            IsOk = false;
            NotFoundEntity = notFoundEntity;
        }

        public string NotFoundEntity { get; set; }
    }

    public class NotFoundOperationResult<T> : OperationResult<T>
    {
        public NotFoundOperationResult(string notFoundEntity)
        {
            IsOk = false;
            NotFoundEntity = notFoundEntity;
        }

        public string NotFoundEntity { get; set; }
    }
    
    public class FailedOperationResult : OperationResult
    {
        public FailedOperationResult()
        {
            IsOk = false;
        }

        public required List<Error> Errors { get; set; }
    }

    public class FailedOperationResult<T> : OperationResult<T>
    {
        public FailedOperationResult()
        {
            IsOk = false;
        }

        public required List<Error> Errors { get; set; }
    }

    public class OperationResult<T> : OperationResult
    {
        public T? Data { get; set; }

        public static OperationResult<T> Success(T data) => new() { IsOk = true, Data = data };
        //public static OperationResult<T> Fail(T? data, List<string>? errors) => new() { Data = data, Errors = errors };
        public static new FailedOperationResult<T> Fail(params Error[] errors) => new() { Errors = errors.ToList() };
        public static new NotFoundOperationResult<T> NotFound(string entityName) => new(entityName);
    }
}