To create migration run this in api folder:

```
dotnet ef migrations add "Initial-Migration" -p ../Invee.Migrations.Sqlite -- --Database.Type=sqlite
```