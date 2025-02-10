using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Invee.Migrations.Sqlite.Migrations
{
    /// <inheritdoc />
    public partial class AddIndexToBorrowingStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Borrowing_Items_ItemId",
                table: "Borrowing");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Borrowing",
                table: "Borrowing");

            migrationBuilder.RenameTable(
                name: "Borrowing",
                newName: "Borrowings");

            migrationBuilder.RenameIndex(
                name: "IX_Borrowing_ItemId",
                table: "Borrowings",
                newName: "IX_Borrowings_ItemId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Borrowings",
                table: "Borrowings",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_Borrowings_Status",
                table: "Borrowings",
                column: "Status");

            migrationBuilder.AddForeignKey(
                name: "FK_Borrowings_Items_ItemId",
                table: "Borrowings",
                column: "ItemId",
                principalTable: "Items",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Borrowings_Items_ItemId",
                table: "Borrowings");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Borrowings",
                table: "Borrowings");

            migrationBuilder.DropIndex(
                name: "IX_Borrowings_Status",
                table: "Borrowings");

            migrationBuilder.RenameTable(
                name: "Borrowings",
                newName: "Borrowing");

            migrationBuilder.RenameIndex(
                name: "IX_Borrowings_ItemId",
                table: "Borrowing",
                newName: "IX_Borrowing_ItemId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Borrowing",
                table: "Borrowing",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Borrowing_Items_ItemId",
                table: "Borrowing",
                column: "ItemId",
                principalTable: "Items",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
