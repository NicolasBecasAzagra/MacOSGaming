# MacOSGaming — Registro de Validaciones y Benchmarks

Este directorio contiene la documentación, protocolos y reportes estandarizados de validación de videojuegos en macOS sobre Apple Silicon.

## Documentos y Enlaces Clave
- **Protocolo de Validación:** [procedure.md](file:///Volumes/PortableSSD/MacOsGaming/MacOSGaming/docs/validation/procedure.md) — Metodología paso a paso, directrices legales y criterios de evaluación.
- **Reporte de Referencia (Dota 2):** [dota-2-report.md](file:///Volumes/PortableSSD/MacOsGaming/MacOSGaming/docs/validation/dota-2-report.md) — Reporte generado automáticamente para juego nativo con renderizado Metal.

## Cómo Ejecutar una Validación
Utilice el comando CLI `validate`:
```bash
# Validación con simulación dry-run
swift run macosgaming validate <game-id> --dry-run

# Validación de juego real con timeout de 30 segundos y reintento automático
swift run macosgaming validate <game-id> --timeout 30 --retry

# Validación con ruta explícita al ejecutable
swift run macosgaming validate <game-id> --path "/ruta/al/juego.exe" --timeout 45
```

## Garantía de Privacidad y Sanitización
Todos los reportes generados en esta carpeta cumplen estrictamente la política de **cero filtración de datos privados**:
- No se registran nombres de usuario ni rutas absolutas locales (`/Users/...`).
- No se registran identificadores de hardware, números de serie, direcciones IP ni claves de producto.
- Todas las rutas se normalizan en formato relativo (`~` o `<EXTERNAL_STORAGE>`).
