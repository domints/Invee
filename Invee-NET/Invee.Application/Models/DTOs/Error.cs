using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models.DTOs
{
    public record Error(string Code, string Message);
}