# Skill: Manejo de Incidentes Chileno

## Propósito

Protocolo de respuesta a incidentes en producción con comunicación clara
en español chileno. Urgencia sin pánico, información sin burocracia.

## Cuándo usar

Cuando algo se cae en producción, hay un bug crítico, o el equipo
necesita coordinar una respuesta rápida.

## Instrucciones

### 1. Niveles de severidad

| Nivel | Nombre chileno | Qué significa | Tiempo de respuesta |
|-------|---------------|---------------|---------------------|
| P0 | "Está la cagá" | Servicio caído, usuarios afectados | Ahora mismo |
| P1 | "Hay un drama serio" | Feature principal rota, workaround existe | < 1 hora |
| P2 | "Hay un tema" | Bug afecta a algunos usuarios | < 4 horas |
| P3 | "Hay una cosita" | Bug menor, nadie lo nota mucho | Próximo sprint |

### 2. Protocolo de comunicación

**Fase 1: Detección** (primeros 5 minutos)
```
🚨 INCIDENTE — [P0/P1/P2] — [descripción corta]
Qué pasó: [lo que sabemos]
Impacto: [a quién afecta]
Quién está mirando: [nombre]
Canal: [#incidents / slack / etc]
```

**Fase 2: Investigación** (5-30 minutos)
```
📋 UPDATE — [timestamp]
Estado: Investigando
Encontré: [lo que sabemos hasta ahora]
Siguiente paso: [qué vamos a hacer]
ETA: [estimación honesta o "no sé todavía"]
```

**Fase 3: Fix** (cuando se encuentra la solución)
```
🔧 FIX EN CAMINO — [timestamp]
Root cause: [qué causó el problema]
Fix: [qué estamos haciendo]
Deploy: [cuándo sale]
Rollback: [si es necesario, ya se hizo]
```

**Fase 4: Resolución**
```
✅ RESUELTO — [timestamp]
Duración: [cuánto duró el incidente]
Qué pasó: [resumen en 2 oraciones]
Fix: [qué se hizo]
Post-mortem: [mañana a las X / link al doc]
```

### 3. Frases para cada fase

**Detección:**
- "Se cayó la wea. Estoy revisando."
- "Hay un cagazo en [servicio]. Voy a investigar."
- "Me llegó alerta de [monitor]. Mirando."

**Investigación:**
- "Ya, encontré algo. Parece que el problema está en [componente]."
- "Todavía no cacho qué pasó, sigo investigando."
- "Necesito que alguien revise [cosa] mientras yo miro [otra cosa]."

**Fix:**
- "Ya tengo el fix. Voy a hacer deploy."
- "El fix ya está arriba. Monitoreando."
- "Tuve que hacer rollback. El fix necesita más testing."

**Resolución:**
- "Listo, ya está todo andando de nuevo."
- "Se arregló. Mañana hacemos post-mortem, ahora a descansar."
- "El incidente duró [X]. Nadie la cagó, el sistema tenía un gap."

### 4. Reglas de oro

1. **Nunca culpar:** "El sistema permitió esto" > "Fulanito la cagó"
2. **Comunicar siempre:** Silencio = pánico. Aunque no sepas nada, di "sigo investigando"
3. **Honestidad brutal:** "No sé cuánto va a demorar" es mejor que una estimación inventada
4. **Cuidar al equipo:** Después de un P0, "vayan a descansar" no es opcional

### 5. Post-mortem

```
## 📝 Post-mortem — [fecha] — [título del incidente]

### Timeline
- [HH:MM] Se detectó el problema
- [HH:MM] Se identificó el root cause
- [HH:MM] Se aplicó el fix
- [HH:MM] Se verificó que todo andaba

### Root cause
[Explicación técnica clara]

### Qué salió bien
- [cosas que funcionaron en la respuesta]

### Qué salió mal
- [cosas que fallaron o se demoraron]

### Action items
- [ ] [cosa que hay que arreglar para que no pase de nuevo]
- [ ] [mejora al monitoreo/alertas]
- [ ] [documentación que falta]

### Aprendizaje pa'l equipo
[Lo que todos deberían saber para la próxima]
```

## Mnemo Integration

| Acción | Cuándo | Qué guardar |
|--------|--------|-------------|
| Store | Después del incidente | Root cause, fix, timeline como memoria tipo "bugfix" |
| Store | Post-mortem | Action items y aprendizajes como tipo "learning" |
| Recall | Durante investigación | Incidentes similares pasados |
