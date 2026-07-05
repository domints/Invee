namespace Invee.Application.Models.DTOs
{
    public class ImageDto
    {
        public int Id { get; set; }
        public required string Url { get; set; }
        public int Order { get; set; }
    }
}
