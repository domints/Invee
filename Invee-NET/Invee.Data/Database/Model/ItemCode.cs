using Invee.Data.Enums;

namespace Invee.Data.Database.Model
{
    public class ItemCode
    {
        public int Id { get; set; }
        public int ItemId { get; set; }
        public CodeType CodeType { get; set; }
        public required string Contents { get; set; }

        public virtual Item? Item { get; set; }
    }
}
