---
title: "Create StatusHUD.svelte - System metrics display"
labels:
  - ui
  - frontend
  - jules
  - phase-5
  - component
assignees: ["jules"]
---

## Descripción

Crear un HUD (Heads-Up Display) que muestre métricas del sistema en tiempo real.

## Tareas

- [ ] Crear `src/lib/components/StatusHUD.svelte`
- [ ] Mostrar uso de GPU/CPU
- [ ] Mostrar Token Balance (ProofOfSentience)
- [ ] Mostrar estado de conexión P2P
- [ ] Gráfico de actividad en tiempo real
- [ ] Animaciones suaves

## Criterios de Aceptación

- [ ] Datos se actualizan en tiempo real
- [ ] No bloquea el UI principal
- [ ] Estilo consistente con tema cyberpunk

## Mockup Visual

```
┌──────────────────────┐
│ ◉ SYNAPSE v0.1.0     │
├──────────────────────┤
│ CPU: ████████░░ 78%  │
│ MEM: ██████░░░░ 56%  │
│ P2P: ● Connected (3) │
├──────────────────────┤
│ TOKENS: 1,247 ◆      │
│ ▁▂▃▅▆▇█▆▅▃▂▁ (24h)   │
└──────────────────────┘
```

## Dependencias
- Requiere: FEAT_tauri-svelte-setup

## Referencia
- `.✨/ARCHITECTURE.md` - ProofOfSentience
