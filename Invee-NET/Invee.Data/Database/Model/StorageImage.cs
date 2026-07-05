using Microsoft.EntityFrameworkCore;

namespace Invee.Data.Database.Model
{
    [PrimaryKey(nameof(StorageId), nameof(ImageId))]
    public class StorageImage
    {
        public int StorageId { get; set; }
        public int ImageId { get; set; }
        public int Order { get; set; }

        public virtual Storage? Storage { get; set; }
        public virtual Image? Image { get; set; }
    }
}
