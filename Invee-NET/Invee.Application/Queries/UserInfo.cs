using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries
{
    public record UserInfo(ClaimsPrincipal User) : IRequest<UserInfoDTO>;
}