using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Enums;

namespace Invee.Application.Models.DTOs
{
    public class BorrowingDTO
    {
        public BorrowingStatus Status { get; set; }
        public DateTime? Start { get; set; }
        public DateTime? End { get; set; }
        public DateTime? Update { get; set; }
        public required string Borrower { get; set; }
        public string? Comment { get; set; }
        public bool Incomplete { get; set; }
    }
}