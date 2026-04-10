using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Invee.Application.Models.DTOs
{
    public class UserInfoDTO
    {
        public bool Authorized { get; set; }
        public string? Name { get; set; }
        public string? Username { get; set; }
    }
}