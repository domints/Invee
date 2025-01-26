using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models
{
    public class OperationResult
    {
        public bool IsOk { get; set; }
        public bool IsNotFound { get; set; }
        public List<string>? Errors { get; set; }
        public static OperationResult Success() => new() { IsOk = true };
        public static OperationResult Fail(List<string>? errors) => new() { Errors = errors };
        public static OperationResult NotFound() => new() { IsNotFound = true };

        public static OperationResult<T> Success<T>(T data) => new() { IsOk = true, Data = data };
    }

    public class OperationResult<T> : OperationResult
    {
        public T? Data { get; set; }

        public static OperationResult<T> Success(T data) => new() { IsOk = true, Data = data };
        public static OperationResult<T> Fail(T? data, List<string>? errors) => new() { Data = data, Errors = errors };
        public static new OperationResult<T> Fail(List<string>? errors) => new() { Errors = errors };
        public static new OperationResult<T> NotFound() => new() { IsNotFound = true };
    }
}