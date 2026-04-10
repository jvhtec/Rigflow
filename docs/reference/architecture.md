# RigFlow Architecture / Arquitectura de RigFlow

## 1) Purpose (EN)
RigFlow is an AutoLISP command (`RIGFLOW`) that automates placement of rigging audio blocks (`1T AUDIO`, `2T AUDIO`) and writes key attributes (label and load) into inserted block references.

## 1) Propósito (ES)
RigFlow es un comando AutoLISP (`RIGFLOW`) que automatiza la colocación de bloques de rigging de audio (`1T AUDIO`, `2T AUDIO`) y escribe atributos clave (etiqueta y carga) en las referencias insertadas.

---

## 2) Runtime flow (EN)
1. User launches `RIGFLOW`.
2. Script validates/loads block definitions from:
   - Current drawing block table, or
   - External library folder (`*rg-block-library*`, default `C:/CAD/RIGBLOCKS/`).
3. User selects rig geometry and options (main, outfill, flown subs, mirror).
4. Script computes placement points, optionally previewing helper entities.
5. Script inserts block references and writes attributes:
   - `LABEL` (`*rg-tag-name*`)
   - `LOAD` (`*rg-tag-weight*`)
6. Script clears temporary previews and prints summary.

## 2) Flujo en ejecución (ES)
1. El usuario ejecuta `RIGFLOW`.
2. El script valida/carga definiciones de bloques desde:
   - La tabla de bloques del dibujo actual, o
   - Carpeta de librería externa (`*rg-block-library*`, por defecto `C:/CAD/RIGBLOCKS/`).
3. El usuario selecciona geometría y opciones (main, outfill, flown subs, mirror).
4. El script calcula puntos de colocación, opcionalmente mostrando previsualizaciones.
5. El script inserta referencias de bloque y escribe atributos:
   - `LABEL` (`*rg-tag-name*`)
   - `LOAD` (`*rg-tag-weight*`)
6. El script limpia previsualizaciones temporales y muestra un resumen.

---

## 3) Modular file structure (EN)

The codebase is split into 9 purpose-based modules in `src/`. Only `rigflow_main.lsp` needs to be added to the Startup Suite; it loads all other modules automatically.

| # | File | Responsibility |
|---|------|---------------|
| 1 | `rig_config.lsp` | All constants and configuration (`*rg-*` globals) |
| 2 | `rig_utils.lsp` | Vector math, formatting, logging, generic prompt helpers |
| 3 | `rig_blocks.lsp` | Block existence, unit conversion, loading, insertion, attributes |
| 4 | `rig_preview.lsp` | Preview entity creation and lifecycle management |
| 5 | `rig_geometry.lsp` | Pair generation, circle projection, sub positioning, mirroring |
| 6 | `rig_records.lsp` | Record structure, accessors, preview/mirror wrappers |
| 7 | `rig_numbering.lsp` | Role/side ranking, sorting, final insertion with numbering |
| 8 | `rig_collectors.lsp` | Interactive collection of main, outfill, and flown sub elements |
| 9 | `rigflow_main.lsp` | Module loader and `c:RIGFLOW` command definition |

Load order follows the dependency chain (1 through 9). The original monolithic file `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` is retained as a reference.

## 3) Estructura modular de archivos (ES)

El código se divide en 9 módulos por responsabilidad en `src/`. Solo `rigflow_main.lsp` necesita añadirse al Startup Suite; carga todos los demás módulos automáticamente.

| # | Archivo | Responsabilidad |
|---|---------|----------------|
| 1 | `rig_config.lsp` | Constantes y configuración (globales `*rg-*`) |
| 2 | `rig_utils.lsp` | Matemáticas vectoriales, formato, logging, prompts genéricos |
| 3 | `rig_blocks.lsp` | Existencia de bloques, conversión de unidades, carga, inserción, atributos |
| 4 | `rig_preview.lsp` | Creación y ciclo de vida de entidades de previsualización |
| 5 | `rig_geometry.lsp` | Generación de pares, proyección circular, posicionamiento de subs, espejo |
| 6 | `rig_records.lsp` | Estructura de registros, accesores, wrappers de preview/espejo |
| 7 | `rig_numbering.lsp` | Ranking de rol/lado, ordenamiento, inserción final con numeración |
| 8 | `rig_collectors.lsp` | Recolección interactiva de elementos main, outfill y flown subs |
| 9 | `rigflow_main.lsp` | Cargador de módulos y definición del comando `c:RIGFLOW` |

El orden de carga sigue la cadena de dependencias (1 a 9). El archivo monolítico original `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` se conserva como referencia.

---

## 4) Persistence model (EN)
### What persists automatically
- Inserted block references and their attribute values persist in the DWG after save.
- If block definitions are present in the drawing, they persist inside the DWG and do not depend on external files next time.

### What does **not** persist automatically
- Temporary preview entities are intentionally deleted.
- Session-only global variables are reset when AutoCAD closes.

### Recommended persistent-data strategy (for future enhancement)
Store RigFlow metadata in drawing dictionaries/Xrecords:
- Root: `(namedobjdict)`
- Create/get custom dictionary key (example: `RIGFLOW_DATA`)
- Store Xrecords using `entmakex` + `dictadd`

> Autodesk reference note: objects created by `entmakex` need an owner to be written to DWG; assign ownership via dictionary APIs.

## 4) Modelo de persistencia (ES)
### Qué persiste automáticamente
- Las referencias de bloque insertadas y sus atributos persisten en el DWG al guardar.
- Si las definiciones de bloque están en el dibujo, permanecen dentro del DWG y no dependen de archivos externos en la siguiente apertura.

### Qué **no** persiste automáticamente
- Las entidades temporales de previsualización se eliminan intencionalmente.
- Variables globales de sesión se reinician al cerrar AutoCAD.

### Estrategia recomendada de datos persistentes (mejora futura)
Guardar metadatos de RigFlow en diccionarios/Xrecords del dibujo:
- Raíz: `(namedobjdict)`
- Crear/obtener diccionario personalizado (ejemplo: `RIGFLOW_DATA`)
- Guardar Xrecords con `entmakex` + `dictadd`

> Nota de referencia Autodesk: objetos creados con `entmakex` necesitan propietario para escribirse en DWG; asignar propiedad con APIs de diccionario.

---

## 5) External references consulted (AutoCAD 2025/official docs)
- Auto-loading and startup files (`acad.lsp`, `acaddoc.lsp`, `S::STARTUP`, `APPLOAD` Startup Suite):
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Customization/files/GUID-FDB4038D-1620-4A56-8824-D37729D42520.htm
- `dictadd` reference (AutoLISP 2025):
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-AutoLISP-Reference/files/GUID-5931D6D8-7F6E-4773-B08C-DEC5F9C4A22E.htm
- `namedobjdict` reference:
  https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-AutoLISP-Reference/files/GUID-A1E43B30-EF8C-452E-97F5-8AC201E310EE.htm
- Dictionary objects overview:
  https://help.autodesk.com/cloudhelp/2024/CHS/AutoCAD-MAC-AutoLisp/files/GUID-24E52678-513E-4322-8070-B23C8945DC3D.htm
- `entmakex` caution about owner/persistence:
  https://help.autodesk.com/cloudhelp/2024/JPN/AutoCAD-AutoLISP-Reference/files/GUID-3F9A2EB2-082D-49DD-8EFD-DAD8F6E9AA6A.htm
