---
title: "Create Terminal.svelte - Main chat interface"
labels:
  - ui
  - frontend
  - jules
  - phase-5
  - component
assignees: ["jules"]
---

## Descripción

Crear el componente principal de chat con estilo terminal cyberpunk.

## Tareas

- [ ] Crear `src/lib/components/Terminal.svelte`
- [ ] Input de texto con estilo terminal
- [ ] Historial de mensajes scrollable
- [ ] Diferenciación visual User vs AI
- [ ] Animación de "typing" para respuestas AI
- [ ] Soporte para Markdown en respuestas

## Criterios de Aceptación

- [ ] Estilo terminal retro-futurista
- [ ] Mensajes se renderizan correctamente
- [ ] Input responsivo
- [ ] Scrolling suave

## Mockup Visual

```
┌─────────────────────────────────────────┐
│ > USER: What is the meaning of life?    │
│                                         │
│ SYNAPSE: Based on my analysis...        │
│ ▋ (typing animation)                    │
│                                         │
├─────────────────────────────────────────┤
│ > _                                     │
└─────────────────────────────────────────┘
```

## Dependencias
- Requiere: FEAT_tauri-svelte-setup

## Referencia
- `.✨/ARCHITECTURE.md` - UI Theme
