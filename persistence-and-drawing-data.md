# Persistence & Drawing Data Guide / Guía de Persistencia y Datos en Dibujo

## EN

## 1) What already persists today
RigFlow inserts standard AutoCAD block references with attributes. Once the drawing is saved, these entities and attribute values persist in the DWG and are available after close/reopen.

## 2) Why users still see missing data sometimes
Typical causes are not entity persistence problems, but dependency/setup problems:
- LSP did not auto-load in new session.
- Block library path changed or is unavailable.
- Drawing did not contain embedded block definitions and external DWGs cannot be found.

## 3) Reliable persistence recipe (recommended)
1. Configure auto-load (APPLOAD Startup Suite or `acaddoc.lsp`).
2. Add RigFlow folders to `TRUSTEDPATHS`.
3. In your template (`.dwt`), insert `1T AUDIO` and `2T AUDIO` once, then save template.
4. Always save DWG after running `RIGFLOW`.

## 4) Advanced metadata persistence (optional future enhancement)
If you need to persist custom run metadata (e.g., last options, custom project IDs):
- Use the Named Object Dictionary root (`namedobjdict`).
- Create/add a child dictionary with `dictadd`.
- Store Xrecords.
- Ensure ownership for objects created via `entmakex`; orphan objects are not written to DWG.

## 5) Minimal AutoLISP example pattern (conceptual)
```lisp
(setq nod (namedobjdict))
;; find or create child dictionary "RIGFLOW_DATA"
;; add xrecord and link ownership with dictadd
```

---

## ES

## 1) Qué persiste actualmente
RigFlow inserta referencias de bloque estándar de AutoCAD con atributos. Al guardar el dibujo, esas entidades y atributos persisten en el DWG y siguen disponibles tras cerrar/reabrir.

## 2) Por qué a veces falta información
Normalmente no es un problema de persistencia de entidades, sino de dependencias/configuración:
- El LSP no se cargó automáticamente en la nueva sesión.
- Cambió/no existe la ruta de librería de bloques.
- El dibujo no tenía definiciones embebidas y no se encuentran DWGs externos.

## 3) Receta recomendada de persistencia confiable
1. Configurar carga automática (APPLOAD Startup Suite o `acaddoc.lsp`).
2. Agregar carpetas de RigFlow a `TRUSTEDPATHS`.
3. En la plantilla (`.dwt`), insertar `1T AUDIO` y `2T AUDIO` una vez y guardar.
4. Guardar siempre el DWG después de ejecutar `RIGFLOW`.

## 4) Persistencia avanzada de metadatos (mejora opcional)
Si necesitas persistir metadatos de ejecución (por ejemplo, últimas opciones o IDs de proyecto):
- Usar la raíz Named Object Dictionary (`namedobjdict`).
- Crear/agregar diccionario hijo con `dictadd`.
- Guardar Xrecords.
- Asegurar propietario para objetos creados con `entmakex`; objetos huérfanos no se escriben al DWG.

## 6) Referencias Autodesk (consultadas)
- Auto-loading / startup files / `S::STARTUP` / Startup Suite (AutoCAD 2025):
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Customization/files/GUID-FDB4038D-1620-4A56-8824-D37729D42520.htm
- `dictadd` (AutoLISP 2025):
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-AutoLISP-Reference/files/GUID-5931D6D8-7F6E-4773-B08C-DEC5F9C4A22E.htm
- `namedobjdict`:
  https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-AutoLISP-Reference/files/GUID-A1E43B30-EF8C-452E-97F5-8AC201E310EE.htm
- Dictionary object handling:
  https://help.autodesk.com/cloudhelp/2024/CHS/AutoCAD-MAC-AutoLisp/files/GUID-24E52678-513E-4322-8070-B23C8945DC3D.htm
- `entmakex` ownership caveat:
  https://help.autodesk.com/cloudhelp/2024/JPN/AutoCAD-AutoLISP-Reference/files/GUID-3F9A2EB2-082D-49DD-8EFD-DAD8F6E9AA6A.htm
