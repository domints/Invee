To create a migration, run this in the Api folder (giving it proper conn string, or starting docker container with `docker run -d --name invee-postgres -e POSTGRES_DB=invee -e POSTGRES_USER=invee -e POSTGRES_PASSWORD=invee -p 5432:5432 postgres:17-alpine`):

```
dotnet ef migrations add "Migration-Name" -p ../Invee.Migrations.Postgres -s ../Invee.Migrations.Postgres
```
