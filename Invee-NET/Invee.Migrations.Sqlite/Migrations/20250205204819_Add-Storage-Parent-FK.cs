using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Invee.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddStorageParentFK : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Storages_ParentId",
                table: "Storages",
                column: "ParentId");

            migrationBuilder.AddForeignKey(
                name: "FK_Storages_Storages_ParentId",
                table: "Storages",
                column: "ParentId",
                principalTable: "Storages",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Storages_Storages_ParentId",
                table: "Storages");

            migrationBuilder.DropIndex(
                name: "IX_Storages_ParentId",
                table: "Storages");
        }
    }
}
