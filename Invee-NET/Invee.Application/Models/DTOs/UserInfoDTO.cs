using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models.DTOs
{
    public class UserInfoDTO
    {
        public required string Name { get; set; }
        public required string Username { get; set; }
    }
}