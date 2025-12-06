# 📤 Session Export - Guía Completa

> **Continúa tu trabajo en una nueva ventana de chat sin perder contexto.**

## 🎯 ¿Qué es Session Export?

Session Export es una funcionalidad del Git-Core Protocol que permite **exportar el estado completo de una sesión de trabajo** para continuarla en otra ventana de chat.

### El Problema que Resuelve

| Sin Session Export | Con Session Export |
|-------------------|-------------------|
| Nueva ventana = contexto perdido | Nueva ventana = contexto completo |
| Hay que re-explicar todo | El agente sabe qué hiciste |
| Se olvidan tareas pendientes | Tareas pendientes documentadas |
| Decisiones técnicas perdidas | Decisiones preservadas |

---

## 🚀 Cómo Usar

### Método 1: Botón en Custom Agent (Recomendado)

1. Durante tu sesión de trabajo, haz clic en el botón:

   ```
   📤 Export Session
   ```

2. El agente te preguntará:

   ```
   📝 ¿Qué trabajamos y qué queda pendiente?
   ```

3. Responde con un breve resumen

4. El agente:
   - ✅ Genera archivo `docs/prompts/SESSION_{fecha}_{topic}.md`
   - ✅ **Copia al portapapeles** automáticamente
   - ✅ Muestra confirmación

5. En nueva ventana:
   - Pega (Ctrl+V)
   - Enter
   - ¡Continúa trabajando!

### Método 2: Script PowerShell

```powershell
./scripts/export-session.ps1 -Summary "Descripción del trabajo" -Topic "mi-topic"
```

**Parámetros:**

| Parámetro | Requerido | Descripción |
|-----------|-----------|-------------|
| `-Summary` | ✅ Sí | Resumen del trabajo actual |
| `-Topic` | No | Identificador para el nombre del archivo |
| `-IncludeGitStatus` | No | Incluir estado git (default: true) |
| `-IncludeIssues` | No | Incluir issues asignados (default: true) |
| `-IncludeRecentCommits` | No | Incluir commits recientes (default: true) |
| `-CommitCount` | No | Número de commits a incluir (default: 5) |
| `-AdditionalContext` | No | Contexto adicional personalizado |

**Ejemplo completo:**

```powershell
./scripts/export-session.ps1 `
  -Summary "Implementando OAuth con Google y GitHub" `
  -Topic "oauth-implementation" `
  -CommitCount 10 `
  -AdditionalContext "Usar passport.js, no auth0"
```

### Método 3: Prompt File

En el chat, usa:

```
#prompt:export
```

Esto activa el prompt de exportación que guía al agente.

---

## 📄 Estructura del Archivo Generado

```markdown
---
title: "Session Continuation - oauth-implementation"
type: PROMPT
generated: 2025-12-02 1430
generator: session-exporter
project: Git-Core-Protocol
branch: feat/issue-42-oauth
---

# 🔄 Session Continuation

## 📊 Estado al Exportar
- **Branch:** `feat/issue-42-oauth`
- **Archivos modificados:** 5
- **Último commit:** feat(auth): add OAuth provider config

## ✅ Lo que se completó
- Configuración de providers OAuth
- Middleware de autenticación
- Rutas de callback

## 🚧 Lo que falta
- Tests de integración
- Documentación de endpoints
- Manejo de errores

## 📋 Issues relacionados
- #42: Implementar autenticación OAuth
- #43: Agregar tests de auth

## 📝 Contexto técnico relevante
- Usando passport.js (no auth0)
- Config en src/config/auth.ts
- Tokens guardados en Redis

## 🎯 Siguiente acción recomendada
Implementar tests para el flujo de login con Google

---
*Usar en nueva ventana: `#file:docs/prompts/SESSION_2025-12-02_oauth.md`*
```

---

## 🔄 Flujo Completo

```
┌─────────────────────────────────────────────────────────────┐
│                    SESIÓN ACTUAL                            │
│                                                             │
│  [Trabajando en feature X...]                               │
│                                                             │
│  Usuario: "Necesito continuar mañana"                       │
│           ↓                                                 │
│  [Clic en 📤 Export Session]                                │
│           ↓                                                 │
│  Agente: "📝 ¿Qué trabajamos y qué falta?"                  │
│           ↓                                                 │
│  Usuario: "OAuth con Google, falta GitHub"                  │
│           ↓                                                 │
│  Agente genera SESSION_2025-12-02_oauth.md                  │
│  Agente ejecuta: "..." | Set-Clipboard                      │
│           ↓                                                 │
│  ✅ COPIADO AL PORTAPAPELES                                 │
│     #file:docs/prompts/SESSION_2025-12-02_oauth.md          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
                    [Cierra ventana]
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    NUEVA SESIÓN                             │
│                                                             │
│  Usuario: [Ctrl+V] → #file:docs/prompts/SESSION_xxx.md      │
│           ↓                                                 │
│  Agente lee el archivo y tiene TODO el contexto:            │
│  - Branch actual                                            │
│  - Lo completado                                            │
│  - Lo pendiente                                             │
│  - Issues relacionados                                      │
│  - Decisiones técnicas                                      │
│           ↓                                                 │
│  Agente: "Continuando con OAuth. Faltan tests de GitHub..." │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚠️ Reglas Importantes

### ✅ Hacer

- Usar Session Export cuando vas a cerrar una sesión de trabajo activa
- Eliminar el archivo SESSION_*.md después de usarlo
- Incluir contexto técnico relevante en el resumen

### ❌ No Hacer

- NO usar como documentación permanente
- NO commitear archivos SESSION_*.md al repositorio
- NO incluir información sensible (tokens, passwords)

### 📁 Ubicación de Archivos

```
docs/
└── prompts/
    ├── README.md                           # Documentación
    ├── SESSION_2025-12-02_oauth.md         # ← Temporal, eliminar después
    └── SESSION_2025-12-02_bugfix.md        # ← Temporal, eliminar después
```

---

## 🛠️ Configuración

### Agregar a .gitignore (Recomendado)

Para evitar commitear archivos de sesión accidentalmente:

```gitignore
# Session prompts (temporary)
docs/prompts/SESSION_*.md
```

### Limpieza Automática

Los archivos SESSION_*.md son **temporales**. Puedes crear un script de limpieza:

```powershell
# Eliminar sesiones antiguas (más de 7 días)
Get-ChildItem docs/prompts/SESSION_*.md |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
  Remove-Item -Verbose
```

---

## 🔗 Integración con Agentes

El botón "Export Session" está disponible en estos agentes:

| Agente | Botón |
|--------|-------|
| `protocol-claude` | 📤 Export Session |
| `protocol-gemini` | 🔄 Export Session |
| `protocol-codex` | 🔄 Export Session |
| `protocol-grok` | 🔄 Export Session |
| `architect` | 🔄 Export Session |

El agente especializado `session-exporter` maneja la generación del archivo.

---

## 📊 Comparación con Alternativas

| Método | Pros | Contras |
|--------|------|---------|
| **Session Export** | Automático, estructurado, copiado al clipboard | Requiere archivo temporal |
| Copiar/pegar chat | Simple | Pierde formato, muy largo |
| Notas manuales | Control total | Tedioso, incompleto |
| Memoria del modelo | Nada que hacer | No persiste entre sesiones |

---

## 🐛 Troubleshooting

### El portapapeles no funciona

```powershell
# Verificar que Set-Clipboard está disponible
Get-Command Set-Clipboard

# Alternativa: usar clip.exe
"texto" | clip
```

### El archivo no se genera

1. Verifica que exista `docs/prompts/`:

   ```powershell
   New-Item -ItemType Directory -Path docs/prompts -Force
   ```

2. Verifica permisos de escritura

### El agente no entiende el contexto

- Asegúrate de que el archivo SESSION_*.md tiene YAML frontmatter válido
- Verifica que la ruta en `#file:` sea correcta

---

## 📚 Referencias

- [AGENTS.md](../AGENTS.md) - Configuración de agentes
- [README.md](../README.md) - Documentación principal
- [export-session.ps1](../scripts/export-session.ps1) - Script de exportación
