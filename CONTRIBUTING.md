# Guía de Contribución / Contributing Guide 🤝

¡Gracias por tu interés en contribuir a **MacOSGaming**! Este proyecto es de código abierto (licencia MIT) y su objetivo es proporcionar una plataforma legal, transparente y de alto rendimiento para configurar, lanzar y diagnosticar videojuegos en macOS y Apple Silicon.

Para asegurar un desarrollo riguroso, ético y de calidad enterprise, solicitamos a todos los colaboradores seguir estas pautas.

---

## 🛠️ 1. Configuración del Entorno de Desarrollo

### Prerrequisitos
- **Hardware:** Mac con Apple Silicon (M1, M2, M3, M4 o variantes Pro/Max/Ultra).
- **Sistema Operativo:** macOS Sonoma (14.0+) o macOS Sequoia (15.0+ recomendado para soporte AVX2).
- **Herramientas de Desarrollo:**
  - Xcode 15.0+ o Xcode 16+ con Command Line Tools instaladas (`xcode-select --install`).
  - Swift Toolchain 5.10 o Swift 6.0 (`swift --version`).
  - Git (`git --version`).

### Clonar y Compilar Localmente
```bash
# Clonar el repositorio
git clone https://github.com/NicolasBecasAzagra/MacOSGaming.git
cd MacOSGaming

# Compilar todos los módulos (Core, CLI y App SwiftUI)
swift build

# Compilar en modo Release optimizado
swift build -c release
```

### Ejecutar la App y el CLI
```bash
# Ejecutar el CLI
swift run macosgaming doctor
swift run macosgaming --help

# Ejecutar la aplicación nativa SwiftUI
swift run MacOSGamingApp
```

---

## 🌿 2. Flujo de Trabajo en Git y Ramas

1. Crea siempre una nueva rama desde `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b <tipo>/<nombre-descriptivo>
   ```
2. Convención de prefijos para ramas:
   - `feat/`: Nueva funcionalidad o vista.
   - `fix/`: Corrección de bugs o regresiones.
   - `docs/`: Documentación, guías o perfiles.
   - `test/`: Nuevos tests o mejoras de cobertura.
   - `ci/`: Cambios en GitHub Actions o scripts de compilación.

---

## 📝 3. Convenciones de Commits (Conventional Commits)

Utilizamos el estándar [Conventional Commits v1.0.0](https://www.conventionalcommits.org/):

```
<tipo>(<ámbito opcional>): <descripción concisa en imperativo>

[cuerpo opcional explicando el porqué del cambio]

[pie opcional con issues referenciadas, ej: Closes #12]
```

### Tipos admitidos:
- `feat`: Nueva característica en CLI, Core o App.
- `fix`: Corrección de un fallo o error.
- `docs`: Modificaciones únicamente en documentación (`docs/`, `README.md`, etc.).
- `test`: Adición o refactorización de tests unitarios.
- `ci`: Modificaciones en flujos de integración continua (`.github/workflows/`).
- `refactor`: Cambios en el código que no alteran la funcionalidad ni corrigen bugs.
- `perf`: Mejoras de rendimiento en parsing o detección de hardware.

*Ejemplo:*
```bash
git commit -m "feat(sentinel): add detection for ACE kernel anti-cheat"
```

---

## 🎮 4. Cómo Añadir o Actualizar un Perfil de Juego

Los perfiles de compatibilidad residen en `data/profiles/<game-id>.json`. Todos los perfiles deben ser válidos según `data/profiles/schema.json`.

### 4.1 Principios Éticos y Legales Obligatorios
- **Cero elusión de anti-cheat:** Nunca documentes ni implementes métodos para burlar o desactivar anti-cheats multijugador online. Si un juego requiere drivers Ring-0 (ej. Vanguard, BattlEye en servidores oficiales), su política debe ser `"block_kernel_anticheat"`.
- **Cero piratería:** No enlaces a sitios de descargas no oficiales, cracks o software de distribución ilegal.
- **Fuentes obligatorias:** Todo perfil debe incluir URLs activas (que devuelvan HTTP 200) de fuentes oficiales, wikis públicas verificadas o desarrolladores.

### 4.2 Estructura del Perfil JSON
```json
{
  "id": "mi-juego",
  "name": "Nombre Oficial del Videojuego",
  "publisher": "Nombre del Distribuidor",
  "steam_app_id": 123456,
  "compatibility_status": "likely_compatible",
  "confidence_level": "verified",
  "last_verified": "2026-10-09",
  "anti_cheat": {
    "name": "Easy Anti-Cheat",
    "type": "userspace",
    "supported_on_macos": false,
    "offline_mode_allowed": true
  },
  "launch_policy": "allow_offline_only",
  "policy_notice": "El modo multijugador requiere Windows. El modo historia local se puede ejecutar sin anti-cheat.",
  "recommended_runtime": {
    "graphics_backend": "dxmt",
    "environment_variables": {
      "ROSETTA_ADVERTISE_AVX": "1",
      "WINEMSYNC": "1"
    }
  },
  "sources": [
    "https://store.steampowered.com/app/123456/...",
    "https://en.wikipedia.org/wiki/..."
  ]
}
```

### 4.3 Validación Local del Perfil
Antes de enviar un PR, valida la sintaxis y las URLs:
```bash
# Validar sintaxis JSON
plutil -lint data/profiles/mi-juego.json

# Validar que todas las fuentes responden con HTTP 200
./scripts/validate_sources.sh
```

---

## 🧪 5. Ejecución de Tests y CI Localmente

Antes de abrir un Pull Request, ejecuta la suite completa de tests:

```bash
# Limpiar artefactos temporales
find . -type f -name "._*" -delete

# Ejecutar todos los tests unitarios
swift test -v

# Ejecutar tests de la app SwiftUI exclusivamente
swift test --filter MacOSGamingAppTests -v

# Validar compilación del binario en Release
swift build --product MacOSGamingApp -c release
swift build --product macosgaming -c release

# Validar script de fuentes
./scripts/validate_sources.sh
```

---

## 🚀 6. Enviar un Pull Request

1. Sube tu rama a tu fork o repositorio:
   ```bash
   git push origin <tu-rama>
   ```
2. Abre un Pull Request describiendo con claridad:
   - Resumen de los cambios.
   - Motivación o ticket asociado.
   - Salida del comando `swift test`.
3. Todos los checks de CI en GitHub Actions deben estar en verde antes de la revisión final.
