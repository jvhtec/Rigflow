# RigFlow

RigFlow is a production AutoLISP workflow for audio rigging placement in AutoCAD.

This repository now uses **one primary manual** (this `README.md`) that includes:
- Project overview.
- Installation manual.
- User/Operator manual.
- Troubleshooting and persistence guidance.
- Repository structure.

---

## EN — Repository Layout

```text
Rigflow/
├─ README.md                      # Main project, installation, and user manual
├─ agents.md                      # Contributor/agent guardrails
├─ src/
│  └─ RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp
├─ blocks/
│  ├─ 1T AUDIO.dwg
│  └─ 2T AUDIO.dwg
└─ docs/
   └─ reference/
      ├─ architecture.md
      └─ persistence-and-drawing-data.md
```

### What each folder is for
- `src/`: source code (`RIGFLOW` command implementation).
- `blocks/`: required external DWG block definitions used by the script.
- `docs/reference/`: deeper technical background docs (architecture + persistence internals).

---

## ES — Estructura del repositorio

```text
Rigflow/
├─ README.md                      # Manual principal de proyecto, instalación y uso
├─ agents.md                      # Reglas para colaboradores/agentes
├─ src/
│  └─ RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp
├─ blocks/
│  ├─ 1T AUDIO.dwg
│  └─ 2T AUDIO.dwg
└─ docs/
   └─ reference/
      ├─ architecture.md
      └─ persistence-and-drawing-data.md
```

### Para qué sirve cada carpeta
- `src/`: código fuente (implementación del comando `RIGFLOW`).
- `blocks/`: definiciones DWG externas requeridas por el script.
- `docs/reference/`: documentación técnica detallada (arquitectura + persistencia interna).

---

## EN — Installation Manual (Detailed)

### 1) Requirements
- AutoCAD 2025 (full AutoCAD with AutoLISP support).
- Access to this repository contents.
- Main script:
  - `src/RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`
- Required block files:
  - `blocks/1T AUDIO.dwg`
  - `blocks/2T AUDIO.dwg`

### 2) Recommended deployment paths (Windows)
You can use any paths, but a stable convention is recommended:
- LISP folder: `C:\CAD\RIGFLOW\`
- Block library folder: `C:\CAD\RIGBLOCKS\`

Copy files as follows:
1. Copy `src/RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` to `C:\CAD\RIGFLOW\`
2. Copy `blocks/1T AUDIO.dwg` and `blocks/2T AUDIO.dwg` to `C:\CAD\RIGBLOCKS\`

### 3) Secure-load configuration (`TRUSTEDPATHS`)
AutoCAD secure loading can block scripts/blocks unless locations are trusted.

Add both folders to `TRUSTEDPATHS`:
- `C:\CAD\RIGFLOW\`
- `C:\CAD\RIGBLOCKS\`

### 4) Configure automatic loading (choose one)
#### Option A — Startup Suite (recommended for most users)
1. Run `APPLOAD`.
2. Add `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` to **Startup Suite**.
3. Restart AutoCAD and verify no load error appears.

#### Option B — `acaddoc.lsp` (advanced/user-managed environments)
Add:
```lisp
(load "RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS")
```
Then restart AutoCAD.

### 5) First-run verification checklist
1. Open a test drawing.
2. Run command: `RIGFLOW`
3. Confirm command launches and prompts appear.
4. Insert a small test setup.
5. Save drawing.
6. Close and reopen AutoCAD + drawing.
7. Confirm inserted blocks and attributes remain editable.

### 6) Mandatory production warning
RigFlow requires `1T AUDIO` and `2T AUDIO` definitions. If external block files are unavailable from `*rg-block-library*`, insertion may fail.

**Best practice for robust persistence:** embed both block definitions into project templates (`.dwt`) by inserting each block at least once and saving the template.

### 7) Multi-user/team deployment tips
- Keep a shared standard for paths across all workstations.
- Use consistent script/block versioning.
- Document whether users rely on embedded definitions, external library files, or both.
- Verify `TRUSTEDPATHS` via onboarding checklist for every machine.

---

## ES — Manual de instalación (detallado)

### 1) Requisitos
- AutoCAD 2025 (versión completa con soporte AutoLISP).
- Acceso al contenido del repositorio.
- Script principal:
  - `src/RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`
- Bloques requeridos:
  - `blocks/1T AUDIO.dwg`
  - `blocks/2T AUDIO.dwg`

### 2) Rutas recomendadas de despliegue (Windows)
Puedes usar otras rutas, pero conviene estandarizar:
- Carpeta LISP: `C:\CAD\RIGFLOW\`
- Carpeta de librería de bloques: `C:\CAD\RIGBLOCKS\`

Copiar archivos así:
1. Copiar `src/RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` a `C:\CAD\RIGFLOW\`
2. Copiar `blocks/1T AUDIO.dwg` y `blocks/2T AUDIO.dwg` a `C:\CAD\RIGBLOCKS\`

### 3) Configurar carga segura (`TRUSTEDPATHS`)
La carga segura de AutoCAD puede bloquear scripts/bloques si no están en rutas confiables.

Agregar ambas rutas a `TRUSTEDPATHS`:
- `C:\CAD\RIGFLOW\`
- `C:\CAD\RIGBLOCKS\`

### 4) Configurar carga automática (elige una)
#### Opción A — Startup Suite (recomendada)
1. Ejecutar `APPLOAD`.
2. Agregar `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp` a **Startup Suite**.
3. Reiniciar AutoCAD y validar que no haya error de carga.

#### Opción B — `acaddoc.lsp` (avanzado)
Agregar:
```lisp
(load "RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS")
```
Luego reiniciar AutoCAD.

### 5) Verificación de primera ejecución
1. Abrir un dibujo de prueba.
2. Ejecutar: `RIGFLOW`
3. Confirmar que aparece el flujo de prompts.
4. Insertar un caso pequeño de prueba.
5. Guardar dibujo.
6. Cerrar y reabrir AutoCAD + dibujo.
7. Confirmar que bloques y atributos siguen editables.

### 6) Advertencia obligatoria de producción
RigFlow requiere las definiciones `1T AUDIO` y `2T AUDIO`. Si los archivos no están disponibles desde `*rg-block-library*`, la inserción puede fallar.

**Práctica recomendada para persistencia robusta:** embeber ambas definiciones en plantillas de proyecto (`.dwt`) insertando cada bloque al menos una vez y guardando la plantilla.

### 7) Recomendaciones para equipos multiusuario
- Mantener el mismo estándar de rutas en todos los equipos.
- Usar versionado consistente de script/bloques.
- Documentar si trabajan con definiciones embebidas, librería externa o ambas.
- Verificar `TRUSTEDPATHS` en el checklist de alta de cada estación.

---

## EN — User Manual (Detailed)

### 1) Command
- Enter `RIGFLOW` and press Enter.

### 2) Typical operator workflow
1. Start `RIGFLOW`.
2. Select required rig type / geometry inputs.
3. Configure optional behaviors:
   - Outfill
   - Flown subs
   - Mirror mode
4. Confirm placement points.
5. Confirm attribute labeling and load values.
6. Complete insertion and review summary in command line.

### 3) Naming and numbering behavior
Current numbering sequence in the script:
- Main L: `SX01`, `SX02`
- Main R: `SX03`, `SX04`
- Out L: `SX05`, `SX06`
- Out R: `SX07`, `SX08`
- Sub L: `SX09`, `SX10`
- Sub R: `SX11`, `SX12`

### 4) Weight behavior
- **Single-point mode:** full entered weight is assigned to that point.
- **Pair mode:** entered total weight is split evenly between the pair.

### 5) Persistence expectations
- Inserted blocks + attributes persist after `SAVE`.
- Preview/helper entities are temporary and are cleaned up by design.
- Session globals reset when AutoCAD closes.

### 6) Save/close/reopen checklist
1. Complete rig placement.
2. Save drawing.
3. Close AutoCAD.
4. Reopen drawing.
5. Validate labels/loads and block editability.

### 7) Troubleshooting matrix
- **“Block not found”**
  - Verify block files exist in the configured library folder.
  - Verify names match exactly: `1T AUDIO`, `2T AUDIO`.
- **LISP not loading at startup**
  - Re-check Startup Suite entry, or `acaddoc.lsp` load line.
- **Secure-load warning/failure**
  - Confirm all relevant folders are listed in `TRUSTEDPATHS`.
- **Works on one machine but not another**
  - Compare folder paths, permissions, AutoCAD profile settings, and trusted paths.

---

## ES — Manual de usuario (detallado)

### 1) Comando
- Escribir `RIGFLOW` y presionar Enter.

### 2) Flujo típico de operación
1. Iniciar `RIGFLOW`.
2. Seleccionar tipo de rig / entradas geométricas.
3. Configurar opciones:
   - Outfill
   - Flown subs
   - Mirror
4. Confirmar puntos de colocación.
5. Confirmar etiquetas y valores de carga.
6. Finalizar inserción y revisar resumen en la línea de comandos.

### 3) Comportamiento de nombres y numeración
Secuencia actual en el script:
- Main L: `SX01`, `SX02`
- Main R: `SX03`, `SX04`
- Out L: `SX05`, `SX06`
- Out R: `SX07`, `SX08`
- Sub L: `SX09`, `SX10`
- Sub R: `SX11`, `SX12`

### 4) Comportamiento de peso/carga
- **Modo punto único:** el peso ingresado se asigna completo a ese punto.
- **Modo par:** el peso total ingresado se divide en partes iguales.

### 5) Qué esperar de la persistencia
- Bloques y atributos insertados persisten después de `SAVE`.
- Entidades de previsualización/ayuda son temporales y se eliminan.
- Variables globales de sesión se reinician al cerrar AutoCAD.

### 6) Checklist guardar/cerrar/reabrir
1. Completar colocación.
2. Guardar dibujo.
3. Cerrar AutoCAD.
4. Reabrir dibujo.
5. Validar etiquetas/cargas y edición de bloques.

### 7) Matriz de solución de problemas
- **“Block not found”**
  - Verificar archivos de bloque en la ruta configurada.
  - Verificar nombres exactos: `1T AUDIO`, `2T AUDIO`.
- **LISP no carga al iniciar**
  - Revisar entrada en Startup Suite o línea de carga en `acaddoc.lsp`.
- **Advertencia/error de carga segura**
  - Confirmar que todas las rutas estén en `TRUSTEDPATHS`.
- **Funciona en un equipo pero no en otro**
  - Comparar rutas, permisos, perfil de AutoCAD y rutas confiables.

---

## Autodesk references
- Auto-loading, startup files, Startup Suite:
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Customization/files/GUID-FDB4038D-1620-4A56-8824-D37729D42520.htm
- `dictadd`:
  https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-AutoLISP-Reference/files/GUID-5931D6D8-7F6E-4773-B08C-DEC5F9C4A22E.htm
- `namedobjdict`:
  https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-AutoLISP-Reference/files/GUID-A1E43B30-EF8C-452E-97F5-8AC201E310EE.htm
- Dictionary objects overview:
  https://help.autodesk.com/cloudhelp/2024/CHS/AutoCAD-MAC-AutoLisp/files/GUID-24E52678-513E-4322-8070-B23C8945DC3D.htm
- `entmakex` owner/persistence caveat:
  https://help.autodesk.com/cloudhelp/2024/JPN/AutoCAD-AutoLISP-Reference/files/GUID-3F9A2EB2-082D-49DD-8EFD-DAD8F6E9AA6A.htm
