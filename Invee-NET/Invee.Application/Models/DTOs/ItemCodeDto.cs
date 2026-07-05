using Invee.Data.Enums;

namespace Invee.Application.Models.DTOs
{
    public record ItemCodeDto(int Id, CodeType CodeType, string Contents);
}
