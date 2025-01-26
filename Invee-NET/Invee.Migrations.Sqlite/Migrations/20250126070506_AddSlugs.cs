using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Invee.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddSlugs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Slug",
                table: "Storages",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Slug",
                table: "Items",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Slug",
                table: "Categories",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Slug",
                table: "Storages");

            migrationBuilder.DropColumn(
                name: "Slug",
                table: "Items");

            migrationBuilder.DropColumn(
                name: "Slug",
                table: "Categories");
        }
    }
}
