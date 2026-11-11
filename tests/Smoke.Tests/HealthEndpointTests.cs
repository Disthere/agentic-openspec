using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Smoke.Tests;

/// <summary>
/// Smoke-тест шаблона: доказывает, что приложение поднимается и <c>/health</c> отвечает.
/// Полноценная проверка домена появится вместе с продуктом (PLAN.md §13).
/// </summary>
/// <remarks>
/// <c>ConfigureAwait(false)</c> здесь намеренно НЕ используется: правило xUnit1030 запрещает его
/// в тестах (ломает лимиты параллелизации). Конфликтующее правило MA0004 для тестовых проектов
/// отключено в <c>.editorconfig</c>, так как xUnit1030 в тестах приоритетнее.
/// </remarks>
public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<ApiMarker>>
{
    private readonly WebApplicationFactory<ApiMarker> _factory;

    public HealthEndpointTests(WebApplicationFactory<ApiMarker> factory) => _factory = factory;

    [Fact]
    public async Task HealthReturnsOk()
    {
        var cancellationToken = TestContext.Current.CancellationToken;
        using var client = _factory.CreateClient();

        using var response = await client.GetAsync(new Uri("/health", UriKind.Relative), cancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<HealthResponse>(cancellationToken);

        Assert.NotNull(payload);
        Assert.Equal("ok", payload.Status);
    }
}
