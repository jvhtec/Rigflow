# Installation Manual / Manual de Instalación

## EN — AutoCAD 2025 Installation

### 1) Requirements
- AutoCAD 2025 (full AutoCAD with AutoLISP support).
- File: `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`.
- Block files: `1T AUDIO.dwg`, `2T AUDIO.dwg`.
- Recommended block library folder: `C:\CAD\RIGBLOCKS\`.

### 2) Install files
1. Create folder `C:\CAD\RIGFLOW\`.
2. Copy LSP file there.
3. Create folder `C:\CAD\RIGBLOCKS\`.
4. Copy `1T AUDIO.dwg` and `2T AUDIO.dwg` into `C:\CAD\RIGBLOCKS\`.

### 3) Add trusted locations (important)
Because secure loading is enforced, add both paths to `TRUSTEDPATHS`:
- `C:\CAD\RIGFLOW\`
- `C:\CAD\RIGBLOCKS\`

### 4) Auto-load on every drawing
Preferred options (official Autodesk-supported):
- `APPLOAD` -> Startup Suite -> add `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`, or
- Put `(load "RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS")` in `acaddoc.lsp`.

### 5) Verify installation
In command line:
1. Run `RIGFLOW`.
2. Confirm no “block not found” message appears.
3. Save drawing, close AutoCAD, reopen drawing.
4. Verify inserted blocks and attributes are still present.

### 6) Mandatory warning about block insertion
> RigFlow depends on `1T AUDIO` and `2T AUDIO` definitions.
> If block files are not reachable from `*rg-block-library*`, insertion can fail.
>
> To guarantee persistence across close/reopen and machine transfer, insert at least one instance of each required block in the drawing/template so definitions are embedded in DWG.

---

## ES — Instalación en AutoCAD 2025

### 1) Requisitos
- AutoCAD 2025 (versión completa con soporte AutoLISP).
- Archivo: `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`.
- Bloques: `1T AUDIO.dwg`, `2T AUDIO.dwg`.
- Carpeta recomendada: `C:\CAD\RIGBLOCKS\`.

### 2) Instalar archivos
1. Crear carpeta `C:\CAD\RIGFLOW\`.
2. Copiar el archivo LSP.
3. Crear carpeta `C:\CAD\RIGBLOCKS\`.
4. Copiar `1T AUDIO.dwg` y `2T AUDIO.dwg` en `C:\CAD\RIGBLOCKS\`.

### 3) Agregar ubicaciones confiables (importante)
Por carga segura, agregar ambas rutas en `TRUSTEDPATHS`:
- `C:\CAD\RIGFLOW\`
- `C:\CAD\RIGBLOCKS\`

### 4) Carga automática en cada dibujo
Opciones recomendadas (soportadas por Autodesk):
- `APPLOAD` -> Startup Suite -> agregar `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`, o
- Poner `(load "RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS")` en `acaddoc.lsp`.

### 5) Verificación
En línea de comando:
1. Ejecutar `RIGFLOW`.
2. Confirmar que no aparezca “block not found”.
3. Guardar dibujo, cerrar AutoCAD, reabrir dibujo.
4. Verificar que bloques y atributos insertados sigan presentes.

### 6) Advertencia obligatoria sobre inserción de bloques
> RigFlow depende de las definiciones `1T AUDIO` y `2T AUDIO`.
> Si los archivos no están disponibles desde `*rg-block-library*`, la inserción puede fallar.
>
> Para asegurar persistencia al cerrar/reabrir y al mover archivos entre equipos, inserta al menos una instancia de cada bloque requerido en el dibujo/plantilla para embebir las definiciones en el DWG.

---

## Autodesk references used
- Auto-loading routines / startup files / Startup Suite:
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Customization/files/GUID-FDB4038D-1620-4A56-8824-D37729D42520.htm
