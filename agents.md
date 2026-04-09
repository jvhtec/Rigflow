# Agents Guide / Guía para Agentes

## EN
This repository contains a production AutoLISP workflow for AutoCAD rigging placement.

### Scope
- Main command: `RIGFLOW`.
- Main source file: `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`.
- Required external blocks: `1T AUDIO.dwg`, `2T AUDIO.dwg`.

### Guardrails for contributors
1. Keep command name and attribute tags stable unless explicitly versioned.
2. Preserve bilingual docs (English + Spanish) for all operator-facing manuals.
3. Any persistence-related feature must document:
   - drawing-embedded persistence,
   - startup loading behavior,
   - security/trusted paths implications.
4. Prefer official Autodesk docs for AutoLISP behavior references.

### Persistence note for implementers
If adding custom metadata persistence, use drawing-owned objects (dictionary/Xrecord) and ensure owner linkage; avoid orphan objects created by `entmakex`.

---

## ES
Este repositorio contiene un flujo AutoLISP de producción para colocación de rigging en AutoCAD.

### Alcance
- Comando principal: `RIGFLOW`.
- Archivo principal: `RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.lsp`.
- Bloques externos requeridos: `1T AUDIO.dwg`, `2T AUDIO.dwg`.

### Reglas para colaboradores
1. Mantener estable el nombre del comando y tags de atributos salvo versionado explícito.
2. Conservar documentación bilingüe (inglés + español) en manuales para operadores.
3. Toda función de persistencia debe documentar:
   - persistencia embebida en dibujo,
   - comportamiento de carga al iniciar,
   - implicaciones de seguridad/rutas confiables.
4. Preferir documentación oficial de Autodesk para referencias de comportamiento AutoLISP.

### Nota de persistencia para implementadores
Si se agrega persistencia de metadatos, usar objetos con dueño en el dibujo (diccionario/Xrecord) y asegurar vínculo de propiedad; evitar objetos huérfanos creados con `entmakex`.
