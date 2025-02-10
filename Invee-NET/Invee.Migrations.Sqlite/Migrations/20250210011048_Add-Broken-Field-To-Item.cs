using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Invee.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddBrokenFieldToItem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "Broken",
                table: "Items",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Broken",
                table: "Items");
        }
    }
}
