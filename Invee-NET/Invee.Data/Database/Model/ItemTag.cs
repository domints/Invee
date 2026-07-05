using Microsoft.EntityFrameworkCore;

namespace Invee.Data.Database.Model
{
    [PrimaryKey(nameof(ItemId), nameof(TagId))]
    public class ItemTag
    {
        public int ItemId { get; set; }
        public int TagId { get; set; }

        public virtual Item? Item { get; set; }
        public virtual Tag? Tag { get; set; }
    }
}
