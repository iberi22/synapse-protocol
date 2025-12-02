---
title: "Create Dojo.svelte - Human validation minigame"
labels:
  - ui
  - frontend
  - jules
  - phase-5
  - component
assignees: ["jules"]
---

## Descripción

Crear la interfaz del "Dojo" donde los usuarios validan respuestas de IA para ganar tokens (Human Reinforcement Learning).

## Tareas

- [ ] Crear `src/lib/components/Dojo.svelte`
- [ ] Mostrar pares de respuestas A/B
- [ ] Botones de selección con feedback visual
- [ ] Animación de recompensa de tokens
- [ ] Streak counter (racha de validaciones)
- [ ] Gamificación (badges, levels)

## Criterios de Aceptación

- [ ] Flujo de validación intuitivo
- [ ] Feedback inmediato al seleccionar
- [ ] Tokens se actualizan en StatusHUD
- [ ] Experiencia adictiva pero ética

## Mockup Visual

```
┌─────────────────────────────────────────┐
│           🥋 DOJO - Train AI            │
├─────────────────────────────────────────┤
│ Q: "How do I fix a memory leak?"        │
├──────────────────┬──────────────────────┤
│ A) Check for     │ B) Restart your      │
│ unclosed         │ computer every       │
│ references...    │ hour...              │
│                  │                      │
│ [SELECT A]       │ [SELECT B]           │
├──────────────────┴──────────────────────┤
│ 🔥 Streak: 5    │    +10 ◆ earned!      │
└─────────────────────────────────────────┘
```

## Contexto
- Parte del sistema ProofOfSentience (50% Human Validation)
- Los usuarios entrenan la IA mientras ganan tokens

## Dependencias
- Requiere: FEAT_tauri-svelte-setup

## Referencia
- `.✨/ARCHITECTURE.md` - ProofOfSentience
