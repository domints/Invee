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
    }
}