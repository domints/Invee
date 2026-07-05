using System.IdentityModel.Tokens.Jwt;
using System.Text.Json.Serialization;
using Invee.Api.Endpoints;
using Invee.Api.Services;
using Invee.Application.Services;
using Invee.Data.Database;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.OpenApi;
using Scalar.AspNetCore;
using Unchase.Swashbuckle.AspNetCore.Extensions.Extensions;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "My API", Version = "v1" });
    c.AddEnumsWithValuesFixFilters();
});

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(
        policy =>
        {
            policy.WithOrigins("http://localhost:5173").AllowCredentials();
            policy.AllowAnyMethod();
            policy.AllowAnyHeader();
        });
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
})
.AddCookie()
.AddOpenIdConnect(options =>
{
    var oidcConfig = builder.Configuration.GetSection("OpenIDConnectSettings");

    options.Authority = oidcConfig["Authority"];
    options.ClientId = oidcConfig["ClientId"];
    options.ClientSecret = oidcConfig["ClientSecret"];

    options.SignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.ResponseType = OpenIdConnectResponseType.Code;
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();

    options.SaveTokens = true;
    options.GetClaimsFromUserInfoEndpoint = true;

    options.MapInboundClaims = false;
    options.TokenValidationParameters.NameClaimType = JwtRegisteredClaimNames.Name;
    options.TokenValidationParameters.RoleClaimType = "roles";
    var redirectBaseUrl = oidcConfig["RedirectBaseUrl"];
    options.Events.OnRedirectToIdentityProvider = context =>
    {
        if (context.Request.Path != "/api/auth")
        {
            var baseUrl = string.IsNullOrEmpty(redirectBaseUrl)
                ? context.Request.Scheme + "://" + context.Request.Host
                : redirectBaseUrl.TrimEnd('/');
            context.Response.StatusCode = 401;
            context.Response.Headers["OAuth-Redirect"] = baseUrl + "/api/auth";
            context.Response.Headers["Access-Control-Expose-Headers"] = "OAuth-Redirect";
            context.HandleResponse();
        }
        else if (!string.IsNullOrEmpty(redirectBaseUrl))
        {
            context.ProtocolMessage.RedirectUri = redirectBaseUrl.TrimEnd('/') + "/signin-oidc";
        }
        return Task.CompletedTask;
    };
});
var requireAuthPolicy = new AuthorizationPolicyBuilder()
    .RequireAuthenticatedUser()
    .Build();

builder.Services.AddAuthorizationBuilder()
    .SetFallbackPolicy(requireAuthPolicy);

builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssemblyContaining<Invee.Application.Marker>());

builder.Services.AddScoped<IImageStore, DiskImageStore>();

builder.Services.ConfigureHttpJsonOptions(options =>
{
	// Tell OpenApi generator to report number fields as integers/floats only, not strings
	options.SerializerOptions.NumberHandling = JsonNumberHandling.Strict;
});

var dbType = builder.Configuration.GetValue<string>("Database:Type");
// https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/providers?tabs=dotnet-core-cli#using-one-context-type
switch (dbType)
{
    case "sqlite":
        builder.Services.AddDbContext<InveeContext>(options =>
            options.UseSqlite(builder.Configuration.GetValue<string>("Database:ConnectionString"),
             x => x.MigrationsAssembly(typeof(Invee.Migrations.Sqlite.Marker).Assembly)));
        break;
    case "postgres":
        builder.Services.AddDbContext<InveeContext>(options =>
            options.UseNpgsql(builder.Configuration.GetValue<string>("Database:ConnectionString"),
             x => x.MigrationsAssembly(typeof(Invee.Migrations.Postgres.Marker).Assembly)));
        break;
    default:
        throw new NotSupportedException($"Database type <{dbType}> is not supported (yet?).");
}

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<InveeContext>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.MapOpenApi().AllowAnonymous();
    app.MapScalarApiReference().AllowAnonymous();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("v1/swagger.json", "My API V1");
    });
}

app.UseCors();
app.UseStaticFiles();
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});
app.UseAuthentication();
app.UseAuthorization();


app.MapGroup("/api")
    .MapApis();

app.MapFallbackToFile("index.html")
    .AllowAnonymous();

app.Run();
