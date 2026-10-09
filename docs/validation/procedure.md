# Procedimiento y Protocolo de Validación con Juegos Reales

Este documento detalla el procedimiento técnico estandarizado para validar la ejecución, estabilidad y rendimiento de videojuegos reales en macOS con procesadores Apple Silicon utilizando **MacOSGaming**.

---

## 1. Alcance y Principios Éticos / Legales

1. **Cumplimiento de Términos de Servicio (ToS):**
   - Nunca intente saltarse o burlar sistemas anti-cheat (Easy Anti-Cheat, BattlEye, Vanguard, Ricochet).
   - Juegos multijugador competitivos con anti-cheat a nivel de kernel están bloqueados permanentemente por el **Anti-Cheat Sentinel** de MacOSGaming (`exit code 2`).
   - Para juegos que soportan modo sin conexión individual (ej. *Elden Ring* o *GTA V modo historia*), la validación debe realizarse exclusivamente con consentimiento explícito y argumentos de desactivación oficiales (`-nobattleye`, `-offline`, etc.).
2. **Sin DRM Alterado:**
   - MacOSGaming no altera binarios, no descifra ejecutables protegidos ni elude DRM.
   - Se validan únicamente juegos legalmente adquiridos a través de plataformas oficiales como Steam, GOG o Epic Games Store.
3. **Privacidad y Sanitización de Datos (Zero-Leakage Policy):**
   - Los reportes generados en `docs/validation/` **nunca deben contener datos personales, nombres de usuario de macOS (`/Users/<username>`), identificadores de hardware, números de serie, direcciones IP ni claves de licencia**.
   - Toda ruta absoluta de usuario debe normalizarse a `~` o identificadores abstractos (`<EXTERNAL_STORAGE>`).

---

## 2. Tipos de Validación Soportados

| Tipo de Juego | Ejemplo Típico | Capa de Ejecución | Backend Gráfico | Riesgo Anti-Cheat |
|---|---|---|---|---|
| **Nativo macOS** | Dota 2, Baldur's Gate 3 | Binario nativo ARM64 / Rosetta 2 | Metal Nativo | Ninguno (Soporte oficial) |
| **Windows DX11 (Indie / Ligero)** | Vampire Survivors, Hollow Knight, Celeste | Wine-CX aislado | DXMT (D3D11 -> Metal) | Nulo (Single-player / Sin AC) |
| **Windows DX11 / DX12 (AAA Offline)** | Elden Ring, GTA V (Story) | Wine-CX aislado | DXMT / DXVK / D3DMetal | Bajo (Solo offline con flags) |
| **Windows Kernel AC (Bloqueado)** | Valorant, Fortnite | N/A (Bloqueado) | N/A | **Bloqueo Crítico por Sentinel** |

---

## 3. Procedimiento de Validación Paso a Paso

### Paso 1: Diagnóstico de Preparación del Sistema
Antes de validar cualquier juego, ejecute el diagnóstico de hardware y subsistemas:
```bash
swift run macosgaming doctor
```
Verifique:
- **Gaming Readiness Score:** >= 60 para juegos 3D ligeros/nativos, >= 75 para títulos AAA.
- **Rosetta 2:** Instalado y activo.
- **Soporte AVX2:** Activo si corre en macOS 15.0+ (Sequoia) para juegos que requieren extensiones AVX2.

### Paso 2: Verificación de Runtimes y Dependencias
Compruebe que los runtimes necesarios están disponibles:
```bash
swift run macosgaming setup
```
- Para juegos nativos de macOS: no se requieren DLLs de DirectX ni Wine.
- Para juegos de Windows vía pasarela: asegúrese de contar con `Wine-CX` instalado (`brew install --cask gcenx/wine/wine-crossover`) y `DXMT` en `~/Library/Application Support/MacOSGaming/runtimes/dxmt/`.

### Paso 3: Detección del Juego en la Biblioteca Steam
Identifique el juego en su biblioteca local de Steam:
```bash
swift run macosgaming steam
```
O verifique el perfil en el registro:
```bash
swift run macosgaming info <game-id>
```

---

### Paso 4: Ejecución del Protocolo de Validación

#### Caso A: Validación de Juego Nativo (Ejemplo: Dota 2)
Dota 2 cuenta con cliente nativo para macOS con backend de renderizado Metal.
1. Ejecute la validación con límite de tiempo de prueba (ej. 30 segundos) o modo dry-run:
   ```bash
   swift run macosgaming validate dota-2 --timeout 30
   ```
2. La pasarela:
   - Resuelve el ejecutable `dota2.app` en la biblioteca Steam.
   - Aplica el perfil nativo sin inicializar Wine ni sobrecargar DLLs de DirectX.
   - Captura el flujo de salida en tiempo real.
   - Mide el tiempo de inicialización de motor (`startup initialization time`).
   - Genera el reporte estandarizado en `docs/validation/dota-2-report.md`.

#### Caso B: Validación de Juego Indie Windows con DXMT (Ejemplo: Vampire Survivors)
1. Instale el juego en el cliente Steam de Windows o descargue su versión DRM-free oficial.
2. Si el juego no está mapeado por defecto en `data/profiles/`, pase la ruta explícita del ejecutable:
   ```bash
   swift run macosgaming validate <game-id> --path "/path/to/game.exe" --timeout 45 --retry
   ```
3. La pasarela:
   - Inicializa el sandbox de prefijo Wine aislado en `~/Library/Application Support/MacOSGaming/prefixes/<game-id>`.
   - Inyecta `WINEMSYNC=1`, `ROSETTA_ADVERTISE_AVX=1` y `WINEDLLOVERRIDES="d3d11=n,b;dxgi=n,b"`.
   - Si la inicialización de DXMT falla, el flag `--retry` activa automáticamente la configuración de respaldo (DirectX estándar / DXVK y desactivación de fastpath msync).
   - Genera el reporte en `docs/validation/<game-id>-report.md`.

#### Caso C: Validación de Título con Modo Offline (Ejemplo: Elden Ring)
1. Ejecute con consentimiento explícito de modo individual sin conexión:
   ```bash
   swift run macosgaming validate elden-ring --offline --timeout 60
   ```
2. La pasarela:
   - Comprueba con el AntiCheat Sentinel que el juego autoriza modo offline seguro.
   - Inyecta los argumentos de desactivación de anti-cheat oficiales del perfil.
   - Inicia el juego en sandbox estricto.

---

## 4. Métricas Clave de Evaluación y Criterios de Aprobación

Cada reporte de validación evalúa:

1. **Tiempo de Arranque (Startup Initialization Time):**
   - *Excelente:* < 500 ms (Juego nativo o sandbox reutilizado).
   - *Aceptable:* 500 ms - 4000 ms (Inicialización de prefijo Wine y compilación inicial de shaders).
   - *Lento / Investigar:* > 8000 ms.

2. **Rendimiento / Tasa de Cuadros (FPS):**
   - Extraída automáticamente del flujo de log si el motor o HUD emite datos de framerate.
   - Si no se emite en texto, se calcula una estimación basada en la GPU Metal del chip Apple Silicon detectado y la complejidad del perfil.

3. **Clasificación Diagnóstica (`DiagnosticClassifier`):**
   - 0 coincidencias críticas (ausencia de abortos por drivers `.sys`, DLLs de VC++ faltantes o instrucciones ilegales).

4. **Estabilidad y Salida Limpia:**
   - Código de salida `0`.
   - En caso de terminación forzada o timeout, el manejador de señales (`SIGINT`/`SIGTERM`) garantiza el cierre ordenado sin corrupción del registro del prefijo Wine.
