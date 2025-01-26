using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Invee.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddQuantityTypeAndNote : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Note",
                table: "Items",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "QuantityType",
                table: "Items",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Note",
                table: "Items");

            migrationBuilder.DropColumn(
                name: "QuantityType",
                table: "Items");
        }
    }
}
