using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Invee.Application.Models.DTOs;
using MediatR;

namespace Invee.Application.Queries
{
    public class UserInfoHandler : IRequestHandler<UserInfo, UserInfoDTO>
    {
        public Task<UserInfoDTO> Handle(UserInfo request, CancellationToken cancellationToken)
        {
            var identity = request.User.Identity as ClaimsIdentity;
            return Task.FromResult(new UserInfoDTO
            {
                Name = identity?.Name ?? "NO NAME?",
                Username = identity?.FindFirst("preferred_username")?.Value ?? identity?.FindFirst("nickname")?.Value ?? "NO USERNAME?"
            });
        }
    }
}