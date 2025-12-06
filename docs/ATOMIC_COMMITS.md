---
title: "Guía de Commits Atómicos"
type: GUIDE
id: "guide-atomic-commits"
created: 2025-12-01
updated: 2025-12-01
agent: copilot
model: gemini-3-pro
requested_by: system
summary: |
  Guía práctica para crear commits atómicos, claros y reversibles.
keywords: [git, commits, atomic, guide]
tags: ["#guide", "#git", "#best-practices"]
project: Git-Core-Protocol
---

# ⚛️ Guía de Commits Atómicos

> Una guía práctica para crear commits que cuenten una historia clara y reversible.

---

## 📖 ¿Qué es un Commit Atómico?

Un **commit atómico** es un commit que representa **un solo cambio lógico** en el código. Tiene tres características esenciales:

| Característica | Descripción |
|----------------|-------------|
| **Único** | Un commit = un cambio lógico |
| **Reversible** | Puede revertirse sin afectar otros cambios |
| **Autocontenido** | Es entendible en aislamiento |

### Analogía

Piensa en los commits como **capítulos de un libro**:

- Cada capítulo cuenta una parte específica de la historia
- Puedes leer un capítulo y entenderlo por sí solo
- Si necesitas quitar un capítulo, los demás siguen teniendo sentido

---

## ❌ Anti-patrones Comunes

### 1. El "Commit Omnibus"

El error más común: meter todo en un solo commit.

```bash
# ❌ MALO: Commit omnibus
git add .
git commit -m "feat: add Jules API Integration with session orchestrator, monitor dashboard, migration scripts, and deployment guide"
```

**Problemas:**

- Imposible de revertir parcialmente
- Difícil de revisar en code review
- Historial de git ilegible
- Descripción demasiado larga (> 72 chars)

### 2. Commits por Archivo

El otro extremo: un commit por cada archivo.

```bash
# ❌ MALO: Commits por archivo sin lógica
git add src/auth.ts && git commit -m "feat: update auth"
git add src/auth.test.ts && git commit -m "test: add auth tests"
git add src/types/auth.ts && git commit -m "feat: add auth types"
```

**Problema:** Los tres archivos son parte del mismo cambio lógico.

### 3. Commits sin Contexto

```bash
# ❌ MALO: Sin contexto
git commit -m "fix stuff"
git commit -m "update code"
git commit -m "changes"
```

**Problema:** No explican el "qué" ni el "por qué".

---

## ✅ Ejemplos de Buenos Commits

### Caso Práctico: Integración de API Jules

Supongamos que necesitas agregar una integración con la API de Jules que incluye:

- Tablas de base de datos
- Lógica del orquestador
- Componente de UI
- Documentación de deployment

```bash
# ✅ BUENO: Commits separados por cambio lógico

# Commit 1: Cambios de base de datos
git add supabase/migrations/
git commit -m "feat(db): add Jules session management tables

Creates tables for storing Jules session state:
- jules_sessions: Active session tracking
- jules_logs: Session activity logs
- jules_configs: User-specific configurations

AI-Context: Uses Supabase migrations. Run with: supabase db push

Refs: #42"

# Commit 2: Lógica de backend
git add src/functions/jules-orchestrator/
git commit -m "feat(api): implement Jules session orchestrator

Adds orchestration layer for Jules API:
- Session creation and management
- Retry logic with exponential backoff
- Error handling and logging

AI-Context: Requires JULES_API_KEY in .env

Refs: #42"

# Commit 3: Componente de UI
git add src/components/JulesSessionManager.svelte
git commit -m "feat(ui): add Jules session manager component

Implements real-time session monitoring with:
- Active session list
- Start/stop controls
- Status indicators

Refs: #42"

# Commit 4: Documentación
git add docs/DEPLOYMENT.md
git commit -m "docs: add Jules deployment guide

Covers:
- Environment setup
- API key configuration
- Health check endpoints

Closes #42"
```

---

## 📊 Tabla de Decisión Rápida

Usa estas preguntas para determinar si debes separar un commit:

| Pregunta | Si "No" → Acción |
|----------|------------------|
| ¿Todos los archivos son del mismo módulo/feature? | Separar por módulo |
| ¿Es un solo tipo de cambio (feat/fix/docs/test)? | Separar por tipo |
| ¿Se puede describir en < 72 caracteres? | Commit muy grande, separar |
| ¿Revertir afectaría solo una cosa? | Separar concerns |
| ¿Un reviewer puede entenderlo fácilmente? | Commit muy complejo |

### Diagrama de Decisión

```
¿El commit hace más de una cosa?
          │
    ┌─────┴─────┐
   Sí          No
    │           │
    ▼           ▼
 Separar     ¿Supera 72 chars el subject?
                    │
              ┌─────┴─────┐
             Sí          No
              │           │
              ▼           ▼
           Separar    ✅ Listo
```

---

## 🔧 Flujo de Trabajo Práctico

### Paso 1: Analiza qué tienes staged

```bash
# Ver estado actual
git status

# Ver diferencias de lo staged
git diff --staged

# Ver diferencias por archivo
git diff --staged --stat
```

### Paso 2: Si hay muchos archivos, analiza por grupos

```bash
# Análisis manual por carpeta
git diff --staged --stat | grep "src/auth"
git diff --staged --stat | grep "src/api"
git diff --staged --stat | grep "tests/"
```

### Paso 3: Unstage todo y agregar por grupos

```bash
# Resetear staging area (mantiene cambios en working directory)
git reset HEAD

# Agregar primer grupo lógico
git add src/auth/
git add src/types/auth.ts
git commit -m "feat(auth): implement OAuth2 login flow"

# Agregar segundo grupo
git add src/api/users/
git commit -m "feat(api): add user management endpoints"

# Agregar tests relacionados
git add tests/auth/
git commit -m "test(auth): add OAuth2 integration tests"

# Agregar documentación
git add docs/AUTH.md
git commit -m "docs: add OAuth2 setup guide"
```

### Paso 4: Verifica el historial

```bash
# Ver los últimos commits
git log --oneline -5

# Resultado esperado:
# a1b2c3d docs: add OAuth2 setup guide
# e4f5g6h test(auth): add OAuth2 integration tests
# i7j8k9l feat(api): add user management endpoints
# m0n1o2p feat(auth): implement OAuth2 login flow
```

---

## 👥 Team vs Solo Developer

Las reglas de commits atómicos se aplican diferente según el contexto:

| Aspecto | Solo Dev | Team |
|---------|----------|------|
| **Pre-commit hook** | Warning (recomendación) | Blocking (obligatorio) |
| **CI Check** | Informativo | Required para merge |
| **Bypass** | Siempre disponible | Requiere aprobación de lead |
| **Squash merges** | Opcional | Generalmente prohibido |
| **Commit message** | Puede ser breve | Requiere contexto completo |

### Configuración para Teams

```bash
# .pre-commit-config.yaml (ejemplo conceptual)
# Nota: Requiere crear el script check-atomic-commit.sh según tus reglas
repos:
  - repo: local
    hooks:
      - id: atomic-commit-check
        name: Check atomic commits
        entry: scripts/check-atomic-commit.sh
        language: script
        stages: [commit]
```

### Configuración para Solo Dev

```bash
# .gitconfig personal
[alias]
    # Mostrar warning pero permitir commit
    atomic-check = "!f() { \
        files=$(git diff --staged --name-only | wc -l); \
        if [ $files -gt 10 ]; then \
            echo '⚠️  Warning: Many files staged. Consider splitting.'; \
        fi; \
    }; f"
```

---

## 📝 Comandos Copy-Paste

### Análisis Rápido

> **Nota:** Estos comandos funcionan en Linux/Mac. En Windows, usa Git Bash o WSL.

```bash
# Contar archivos staged
git diff --staged --name-only | wc -l

# Ver archivos staged agrupados por carpeta (primer nivel)
git diff --staged --name-only | cut -d'/' -f1 | sort | uniq -c | sort -rn

# Ver tipos de archivos staged por extensión
git diff --staged --name-only | grep -o '\.[^.]*$' | sort | uniq -c
```

### Unstage Selectivo

```bash
# Unstage todo
git reset HEAD

# Unstage un archivo específico
git reset HEAD path/to/file.ts

# Unstage una carpeta
git reset HEAD src/feature/

# Unstage archivos por patrón
git reset HEAD "*.test.ts"
```

### Stage Selectivo

```bash
# Stage interactivo (seleccionar hunks)
git add -p

# Stage por carpeta
git add src/auth/

# Stage por extensión
git add "*.ts"

# Stage archivos modificados (no nuevos)
git add -u
```

### Verificación

```bash
# Ver lo que se va a commitear
git diff --staged

# Dry run del commit
git commit --dry-run

# Ver historial limpio
git log --oneline --graph -10
```

---

## 🔗 Integración con Git-Core Protocol

Los commits atómicos son fundamentales para el Git-Core Protocol:

1. **GitHub Issues como estado** → Cada commit debe referenciar un issue
2. **Historial legible** → Commits atómicos = historial claro
3. **AI-Context** → Agrega contexto para futuros agentes AI
4. **Reversibilidad** → Facilita rollbacks precisos

```bash
# Ejemplo de commit atómico con Git-Core Protocol
git commit -m "feat(auth): add password reset flow #15

Implements forgot password functionality:
- Email verification endpoint
- Token generation with 24h expiry
- Password update with validation

AI-Context: Uses SendGrid for emails. Config in src/config/email.ts

Refs: #12
Closes #15"
```

---

## 📚 Recursos Adicionales

- [Conventional Commits](https://conventionalcommits.org)
- [docs/COMMIT_STANDARD.md](./COMMIT_STANDARD.md) - Estándar de mensajes de commit
- [A Note About Git Commit Messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)

---

*Esta guía es parte del Git-Core Protocol. Para más información, consulta el [README principal](../README.md).*

