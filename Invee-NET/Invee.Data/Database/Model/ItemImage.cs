using Microsoft.EntityFrameworkCore;

namespace Invee.Data.Database.Model
{
    [PrimaryKey(nameof(ItemId), nameof(ImageId))]
    public class ItemImage
    {
        public int ItemId { get; set; }
        public int ImageId { get; set; }
        public int Order { get; set; }

        public virtual Item? Item { get; set; }
        public virtual Image? Image { get; set; }
    }
}
