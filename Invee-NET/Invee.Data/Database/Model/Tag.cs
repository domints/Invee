namespace Invee.Data.Database.Model
{
    public class Tag
    {
        public int Id { get; set; }
        public required string Name { get; set; }

        public virtual ICollection<ItemTag>? ItemTags { get; set; }
    }
}
