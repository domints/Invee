using Invee.Data.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Invee.Migrations.Postgres;

public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<InveeContext>
{
    public InveeContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<InveeContext>()
            .UseNpgsql(
                "Host=localhost;Database=invee;Username=invee;Password=invee",
                x => x.MigrationsAssembly(typeof(Marker).Assembly))
            .Options;

        return new InveeContext(options);
    }
}
