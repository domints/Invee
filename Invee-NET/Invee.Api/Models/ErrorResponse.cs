using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models.DTOs;

namespace Invee.Api.Models
{
    public record ErrorResponse(List<Error> Errors);
}