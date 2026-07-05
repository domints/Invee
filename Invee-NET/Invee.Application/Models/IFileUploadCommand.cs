namespace Invee.Application.Models
{
    public interface IFileUploadCommand<TParams, TSelf>
        where TSelf : IFileUploadCommand<TParams, TSelf>
    {
        static abstract TSelf Create(TParams parameters, Stream stream, string fileName, string contentType);
    }
}
