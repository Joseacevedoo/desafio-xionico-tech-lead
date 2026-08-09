# Xionico Orders Mobile

Aplicación Flutter para login de operador, dashboard operativo, consulta de catálogo, registro de pedidos e historial contra la API FastAPI del desafío.

## Arquitectura

La app usa una estructura feature-first:

```text
lib/
  core/
    config/
    di/
    network/
    router/
    storage/
  features/
    auth/
    metrics/
    products/
    orders/
```

Decisiones principales:

- `flutter_bloc` con Cubits para estado.
- `go_router` para navegación y protección por sesión.
- `dio` para HTTP.
- `flutter_secure_storage` para guardar el JWT.
- `get_it` para inyección de dependencias.
- `uuid` para generar `X-Idempotency-Key` al registrar pedidos.

## Pantallas principales

- Login de operador.
- Inicio con métricas operativas.
- Catálogo de productos con búsqueda y pull-to-refresh.
- Nuevo pedido desde el catálogo.
- Confirmación de pedido registrado.
- Historial de pedidos.
- Detalle de pedido por id.

## Configuración de API

La URL base se toma de `API_BASE_URL`:

```dart
const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
)
```

Para Android Emulator, el default apunta al host local donde corre FastAPI.
Esto funciona tanto en debug como en release.

Para un dispositivo físico conectado a la misma red, reemplazar la IP de ejemplo
por la IP local de la computadora que ejecuta Docker:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

Para un ambiente desplegado se debe proporcionar la URL HTTPS correspondiente:

```powershell
flutter run --release --dart-define=API_BASE_URL=https://api.example.com
```

## Ejecutar

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Validación release en Android Emulator:

```powershell
flutter run --release --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Deuda técnica

- Extraer los textos visibles a recursos ARB con `gen_l10n`.
- Mantener español como idioma inicial y preparar soporte para inglés.
- Eliminar strings de interfaz hardcodeados para facilitar traducciones y pruebas por locale.
- Agregar pruebas de UI con distintos locales y tamaños de texto.
- Revisar accesibilidad, contraste, lectores de pantalla y navegación asistida.
- Evaluar funcionamiento offline con cola local y sincronización idempotente.
- Incorporar lectura de códigos de barras o QR para agilizar la selección de productos.
- Completar configuración por ambientes, firma release y pruebas en dispositivos físicos.
