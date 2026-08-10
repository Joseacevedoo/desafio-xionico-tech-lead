# Desafío Tech Lead Xionico

Solución técnica para una PoC de registro de pedidos con aplicación Flutter, API FastAPI y persistencia en SQL Server.

## Video demo y TDR

El video demo y el Registro de Decisiones Técnicas (TDR) están disponibles en la siguiente carpeta de Google Drive:

[Ver video demo y TDR en Google Drive](https://drive.google.com/drive/folders/1SrIABIdsJMJivzRXu5vUGDPlfszlswAo?usp=sharing)

El proyecto está organizado en tres módulos principales:

- `backend`: API REST con FastAPI, SQLAlchemy y pyodbc.
- `mobile`: aplicación Flutter con arquitectura feature-first, Cubit, go_router, Dio, secure storage y get_it.
- `db`: scripts SQL Server para schema, seeds y stored procedure transaccional.

## Alcance implementado

- Login de operador contra SQL Server.
- Emisión y validación de JWT.
- Consulta de sesión autenticada.
- Catálogo paginado de productos activos con búsqueda por código o nombre.
- Armado de pedido desde Flutter.
- Registro de pedido con header `X-Idempotency-Key`.
- Cálculo de hash del pedido para idempotencia.
- Delegación del alta transaccional a `dbo.sp_RegisterOrder`.
- Historial paginado de pedidos.
- Consulta de detalle de pedido por id.
- Visualización de métricas operativas diarias basadas en pedidos por estado y cliente.
- Manejo uniforme de errores de dominio y validación.
- Tests unitarios de backend y Cubits de Flutter.
- Entorno reproducible con Docker Compose para SQL Server, inicialización de base y backend.

## Estructura

```text
my-techlead-challenge/
  backend/
    app/
      auth/
      core/
      metrics/
      orders/
      products/
    tests/
    .env.example
    Dockerfile
    requirements.txt
    comandos_levantar_backend.txt
  db/
    01_schema.sql
    02_procedures.sql
    03_seed_data.sql
    04_app_user.sql
    init-db.sh
  mobile/
    lib/
      core/
      features/
    test/
    pubspec.yaml
  .env.example
  docker-compose.yml
```

La carpeta `db` contiene scripts para crear la base `xionico_orders`, tablas, datos mínimos, el stored procedure `dbo.sp_RegisterOrder` y la vista `dbo.vw_DailyOrderSummary`.

## Ejecución reproducible con Docker

Requisitos: Docker Desktop con contenedores Linux y Docker Compose.

Desde la raíz del repositorio:

```powershell
Copy-Item .env.example .env
```

Reemplazar los tres valores de ejemplo en `.env` por secretos locales seguros y ejecutar:

```powershell
docker compose up -d --build
docker compose ps
```

Compose levanta SQL Server, espera su disponibilidad, ejecuta una sola vez los scripts `01` a `04` mediante `db/init-db.sh` y finalmente inicia FastAPI. La API queda disponible en `http://localhost:8000` y Swagger en `http://localhost:8000/docs`.

Validación rápida:

```powershell
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod http://localhost:8000/health/ready
```

Para detener el entorno sin eliminar los datos:

```powershell
docker compose down
```

## Backend

### Requisitos

- Python compatible con el entorno virtual existente.
- SQL Server disponible.
- ODBC Driver 18 for SQL Server.
- Variables configuradas en `backend/.env`, tomando `backend/.env.example` como base.

Variables principales:

```text
DB_HOST=localhost
DB_PORT=1433
DB_NAME=xionico_orders
DB_USER=xionico_app
DB_PASSWORD=reemplazar
DB_DRIVER=ODBC Driver 18 for SQL Server
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=true
JWT_SECRET_KEY=replace_with_a_secure_random_key
DEFAULT_CUSTOMER_CODE=CUST-DEFAULT
MAX_ORDER_ITEMS=50
MAX_ITEM_QUANTITY=10000
```

### Levantar API

Desde `backend`:

```powershell
.\.venv\Scripts\Activate.ps1
fastapi dev app\main.py
```

Para exponerla a emuladores o dispositivos en la red:

```powershell
fastapi dev app\main.py --host 0.0.0.0
```

La documentación interactiva queda disponible en:

```text
http://127.0.0.1:8000/docs
```

## Base de datos

Ejecutar los scripts de `db` en este orden:

```text
01_schema.sql
02_procedures.sql
03_seed_data.sql
04_app_user.sql
```

Usuario demo incluido:

```text
username: operador
password: Demo123!
```

`04_app_user.sql` crea el login/usuario restringido `xionico_app` con la contraseña provista por el entorno.

### Endpoints implementados

| Método | Ruta | Autenticación | Descripción |
| --- | --- | --- | --- |
| `GET` | `/health` | No | Estado básico de la API. |
| `GET` | `/health/ready` | No | Verifica conectividad con SQL Server. |
| `POST` | `/api/v1/auth/login` | No | Login de operador y emisión de JWT. |
| `GET` | `/api/v1/auth/me` | Sí | Usuario autenticado actual. |
| `GET` | `/api/v1/productos` | Sí | Catálogo paginado con `page`, `page_size` y `search`. |
| `GET` | `/api/v1/pedidos` | Sí | Historial paginado de pedidos. |
| `POST` | `/api/v1/pedidos` | Sí | Registra un pedido. Requiere `X-Idempotency-Key`. |
| `GET` | `/api/v1/pedidos/{order_id}` | Sí | Consulta detalle de un pedido. |
| `GET` | `/api/v1/metricas/resumen-diario` | Sí | Consulta métricas diarias agregadas por estado y cliente. |

## Mobile

### Requisitos

- Flutter SDK.
- Backend levantado y accesible desde el dispositivo o emulador.

La app usa por defecto:

```text
http://10.0.2.2:8000
```

Ese valor funciona para Android Emulator apuntando al host local. Para otro entorno se puede sobreescribir con `API_BASE_URL`.
La configuración Android permite validar la aplicación local tanto en debug como en release.

### Levantar app

Desde `mobile`:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Para un dispositivo físico, usar la IP de la máquina donde corre FastAPI:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

Validación release en Android Emulator:

```powershell
flutter run --release --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Para un despliegue real, indicar la URL HTTPS del backend mediante `API_BASE_URL`.


## Decisiones técnicas

- Comentarios y documentación en español.
- Identificadores internos en inglés.
- Backend modular por dominio: `auth`, `products`, `orders`, `metrics`, `core`.
- Acceso a SQL Server mediante SQLAlchemy Core/Text + pyodbc.
- Operación crítica de pedido resuelta en SQL Server con stored procedure transaccional.
- Idempotencia con UUID enviado por cliente y hash canónico del contenido del pedido.
- Flutter feature-first con separación `data`, `presentation`, Cubits y rutas protegidas.
- JWT almacenado en `flutter_secure_storage` y agregado a requests con interceptor de Dio.
- Docker Compose coordina SQL Server, inicialización idempotente y FastAPI con health checks.

## Deuda técnica

- **Confiabilidad de entrega:** incorporar CI/CD, análisis estático, pruebas de integración sobre Docker, observabilidad, backups y gestión externa de secretos.
- **Inventario logístico:** modelar depósitos, zonas y ubicaciones físicas; separar stock disponible, reservado y comprometido; registrar movimientos, transferencias y trazabilidad. Evaluar lotes y vencimientos según el negocio.
- **Flujo operativo:** agregar selección real de cliente, actualización y cancelación de pedidos con auditoría, además de roles para operador, supervisor y administrador.
- **Operación de campo:** implementar una estrategia offline con cola local, sincronización y resolución de conflictos; evaluar lectura de códigos de barras o QR.
- **Calidad mobile:** internacionalizar textos con recursos ARB y `gen_l10n`, comenzando por español e inglés; sumar pruebas por locale y mejoras de accesibilidad.
- **Seguridad:** incorporar refresh token o una política de sesión más completa y rotación de secretos por ambiente.
- **Escalabilidad:** medir carga y consultas reales antes de introducir caché, réplicas o separación de servicios.
- **Prioridad baja — nomenclatura del paquete Flutter:** renombrar `mobile` a `xionico_app` para adoptar una nomenclatura técnica más representativa del producto. Para la PoC se mantiene `mobile` para evitar un refactor de imports sin impacto funcional; una evolución futura deberá actualizar las referencias `package:mobile/...`.
