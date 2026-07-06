# ── Stage 1: Build Vue SPA ─────────────────────────────────────────────────
FROM node:22-alpine AS spa-build
WORKDIR /app
COPY Invee-Vue/package*.json ./
RUN npm ci
COPY Invee-Vue/ ./
RUN npm run build-only

# ── Stage 2: Build .NET API ────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS api-build
ARG APP_VERSION=unknown
WORKDIR /src
COPY Invee-NET/ ./
RUN dotnet publish Invee.Api/Invee.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-self-contained
RUN echo "${APP_VERSION}" > /app/publish/version.txt

# ── Stage 3: Runtime ───────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=api-build /app/publish ./
COPY --from=spa-build /app/dist ./wwwroot
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "Invee.Api.dll"]