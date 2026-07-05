using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Invee.Application.Models.DTOs;

namespace Invee.Application.Consts
{
    public static class Errors
    {
        public static Error NameDuplicate(string entityName) => new Error("E-001", $"{entityName} with such name already exists");
        public static Error SlugDuplicate(string entityName) => new Error("E-002", $"{entityName} with such slug already exists");
        public static Error NameEmpty() => new Error("E-003", "Name cannot be empty");
        public static Error ReservedOrBorrowed() => new Error("E-004", "Item already reserved or borrowed");
        public static Error InUse(string entityName) => new Error("E-005", $"{entityName} is in use and cannot be deleted");
        public static Error InvalidMove() => new Error("E-006", "Cannot move node under itself or its descendant");
        public static Error InvalidTagIds() => new Error("E-007", "One or more tag IDs are invalid");
        public static Error ContentsEmpty() => new Error("E-008", "Code contents cannot be empty");
        public static Error InvalidImageIds() => new Error("E-009", "One or more image IDs are invalid");
    }
}