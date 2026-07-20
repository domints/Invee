namespace Invee.Api.Configuration
{
    public class ShortLinkOptions
    {
        public const string SectionName = "ShortLinks";

        public string ShortHost { get; set; } = string.Empty;
        public string CanonicalBaseUrl { get; set; } = string.Empty;
    }
}
