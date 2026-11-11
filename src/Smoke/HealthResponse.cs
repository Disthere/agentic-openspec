namespace Smoke;

/// <summary>Ответ эндпоинта <c>/health</c>.</summary>
/// <param name="Status">Признак работоспособности; <c>ok</c> при успехе.</param>
public sealed record HealthResponse(string Status);
