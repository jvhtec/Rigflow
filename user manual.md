# User Manual / Manual de Usuario

## EN — Operator Workflow

### Command
- Type `RIGFLOW` and press Enter.

### Basic process
1. Select the required rig type and geometry points.
2. Optional: enable outfill.
3. Optional: enable flown subs.
4. Optional: apply mirror mode at the end.
5. Confirm placement and numbering.

### Naming and numbering (current script behavior)
- Main L: `SX01`, `SX02`
- Main R: `SX03`, `SX04`
- Out L: `SX05`, `SX06`
- Out R: `SX07`, `SX08`
- Sub L: `SX09`, `SX10`
- Sub R: `SX11`, `SX12`

### Weight behavior
- Single-point mode: full entered weight goes to that point.
- Pair mode: entered total weight is split equally across both points.

### Critical persistence warning
> Inserted blocks and attributes persist in DWG only after saving.
>
> To avoid missing block definitions in future sessions, keep `1T AUDIO` and `2T AUDIO` definitions inside the drawing/template (embed by insertion at least once) OR ensure the block library path remains valid on every workstation.

### Save/close/reopen checklist
1. Run `RIGFLOW` and finish placement.
2. `SAVE` drawing.
3. Close AutoCAD.
4. Reopen DWG.
5. Confirm blocks/attributes are present and editable.

### Troubleshooting
- **“Block not found”**: verify `*rg-block-library*` path and file names.
- **LISP does not load at startup**: verify `APPLOAD` Startup Suite or `acaddoc.lsp` load line.
- **Secure-load issue**: add folders to `TRUSTEDPATHS`.

---

## ES — Flujo del Operador

### Comando
- Escribir `RIGFLOW` y Enter.

### Proceso básico
1. Seleccionar tipo de rig y puntos de geometría.
2. Opcional: activar outfill.
3. Opcional: activar flown subs.
4. Opcional: aplicar mirror al final.
5. Confirmar colocación y numeración.

### Nombres y numeración (comportamiento actual)
- Main L: `SX01`, `SX02`
- Main R: `SX03`, `SX04`
- Out L: `SX05`, `SX06`
- Out R: `SX07`, `SX08`
- Sub L: `SX09`, `SX10`
- Sub R: `SX11`, `SX12`

### Comportamiento de carga/peso
- Modo punto único: el peso total ingresado queda en ese punto.
- Modo par: el peso total ingresado se divide en partes iguales.

### Advertencia crítica de persistencia
> Bloques insertados y atributos persisten en DWG solo después de guardar.
>
> Para evitar pérdida de definiciones de bloque en sesiones futuras, conserva `1T AUDIO` y `2T AUDIO` dentro del dibujo/plantilla (insertar al menos una vez) O asegura que la ruta de librería exista en todos los equipos.

### Lista de verificación guardar/cerrar/reabrir
1. Ejecutar `RIGFLOW` y terminar la colocación.
2. `SAVE` del dibujo.
3. Cerrar AutoCAD.
4. Reabrir DWG.
5. Confirmar que bloques/atributos siguen presentes y editables.

### Solución de problemas
- **“Block not found”**: validar ruta `*rg-block-library*` y nombres de archivos.
- **LISP no carga al iniciar**: validar `APPLOAD` Startup Suite o línea en `acaddoc.lsp`.
- **Problema de carga segura**: agregar carpetas en `TRUSTEDPATHS`.
