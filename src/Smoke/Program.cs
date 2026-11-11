using Smoke;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

// Smoke-эндпоинт: существует только чтобы подтвердить, что шаблон собирается,
// запускается и покрыт тестом с первого клона (PLAN.md, задача 1.1).
app.MapGet("/health", () => Results.Ok(new HealthResponse("ok")));

await app.RunAsync().ConfigureAwait(false);
