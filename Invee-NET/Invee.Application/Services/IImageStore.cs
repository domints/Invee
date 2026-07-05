namespace Invee.Application.Services
{
    public interface IImageStore
    {
        Task<string> StoreAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default);
        Task<(Stream Stream, string ContentType)> RetrieveAsync(string storedPath, CancellationToken ct = default);
        Task DeleteAsync(string storedPath, CancellationToken ct = default);
    }
}
