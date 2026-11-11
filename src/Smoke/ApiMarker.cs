namespace Smoke;

/// <summary>
/// Якорь для <c>WebApplicationFactory&lt;T&gt;</c>: тестам нужен публичный тип из сборки
/// приложения. Намеренно «пустой» тип-маркер, поэтому анализатор S2094 подавлен локально.
/// </summary>
#pragma warning disable S2094 // Marker type: WebApplicationFactory<T> требует публичный тип.
public sealed class ApiMarker
{
}
#pragma warning restore S2094
