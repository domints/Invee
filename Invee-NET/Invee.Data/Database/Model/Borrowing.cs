using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Data.Enums;
using Microsoft.EntityFrameworkCore;

namespace Invee.Data.Database.Model
{
    [Index(nameof(Status))]
    public class Borrowing
    {
        public int Id { get; set; }
        public required string Borrower { get; set; }
        public int ItemId { get; set; }
        public BorrowingStatus Status { get; set; }
        public DateTime? ExpectedStart { get; set; }
        public DateTime? ExpectedReturn { get; set; }
        public DateTime? Created { get; set; }
        public DateTime? Borrowed { get; set; }
        public DateTime? Returned { get; set; }
        public bool Incomplete { get; set; }
        public string? Comment { get; set; }


        public virtual Item? Item { get; set; }
    }
}