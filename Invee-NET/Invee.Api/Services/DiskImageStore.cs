using Invee.Application.Services;

namespace Invee.Api.Services
{
    public class DiskImageStore : IImageStore
    {
        private readonly string _basePath;

        public DiskImageStore(IConfiguration configuration, IWebHostEnvironment env)
        {
            var configuredPath = configuration.GetValue<string>("ImageStorage:BasePath") ?? "uploads";
            _basePath = Path.IsPathRooted(configuredPath)
                ? configuredPath
                : Path.Combine(env.ContentRootPath, configuredPath);

            Directory.CreateDirectory(_basePath);
        }

        public async Task<string> StoreAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default)
        {
            var extension = Path.GetExtension(fileName);
            var storedName = $"{Guid.NewGuid()}{extension}";
            var fullPath = Path.Combine(_basePath, storedName);

            await using var fileStream = new FileStream(fullPath, FileMode.Create, FileAccess.Write, FileShare.None);
            await stream.CopyToAsync(fileStream, ct);

            return storedName;
        }

        public Task<(Stream Stream, string ContentType)> RetrieveAsync(string storedPath, CancellationToken ct = default)
        {
            var fullPath = Path.Combine(_basePath, storedPath);
            if (!File.Exists(fullPath))
                throw new FileNotFoundException("Image file not found.", fullPath);

            Stream stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
            return Task.FromResult((stream, ContentTypeFromPath(storedPath)));
        }

        public Task DeleteAsync(string storedPath, CancellationToken ct = default)
        {
            var fullPath = Path.Combine(_basePath, storedPath);
            if (File.Exists(fullPath))
                File.Delete(fullPath);
            return Task.CompletedTask;
        }

        private static string ContentTypeFromPath(string path)
        {
            return Path.GetExtension(path).ToLowerInvariant() switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };
        }
    }
}
