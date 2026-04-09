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

## 3) Core modules in `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` (EN)
- Configuration constants (block names, library paths, scaling, tags).
- Geometry helpers (vectors, normalization, projection/perpendicular helpers).
- Block availability and insertion pipeline (COM + command fallback).
- Input loops and yes/no guards.
- Preview lifecycle (`*rg-persistent-preview-ents*` + clear routine).
- Final writeback to inserted blocks (attributes + numbering pattern SX01..SX12).

## 3) Módulos principales en `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` (ES)
- Constantes de configuración (nombres de bloques, rutas, escala, tags).
- Ayudas geométricas (vectores, normalización, proyecciones/perpendiculares).
- Flujo de disponibilidad e inserción de bloques (COM + fallback por comando).
- Bucles de entrada y validaciones de sí/no.
- Ciclo de vida de previsualización (`*rg-persistent-preview-ents*` + rutina de limpieza).
- Escritura final en bloques insertados (atributos + numeración SX01..SX12).

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
