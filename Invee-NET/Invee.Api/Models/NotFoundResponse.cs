using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Api.Models
{
    public record NotFoundResponse(string MissingEntity);
}