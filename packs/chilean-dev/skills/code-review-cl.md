# Skill: Code Review Chileno

## Propósito

Hacer code reviews que comuniquen con claridad usando el estilo directo chileno.
No se trata de ser informal — se trata de ser honesto, rápido y humano.

## Cuándo usar

En todo PR review cuando el equipo opera en español chileno.

## Instrucciones

### 1. Estructura del review

```
## 🟢 Lo que quedó filete
- [listar lo bueno primero, siempre]

## 🔴 Hay que arreglar sí o sí (bloqueantes)
- [errores, bugs, security issues — estos no se negocian]

## 🟡 Sugerencias (no bloqueantes)
- [mejoras opcionales — "yo lo haría así pero es idea mía"]

## Veredicto
- "Dale no más po, aprobado ✅" / "Hay que arreglar unas cositas 🔧" / "Chuta, esto necesita re-trabajo 🔄"
```

### 2. Tono por severidad

| Severidad | Tono | Ejemplo |
|-----------|------|---------|
| Crítico | Directo, urgente | "Esto hay que arreglarlo sí o sí — hay SQL injection acá" |
| Importante | Firme pero constructivo | "Esto anda, pero va a ser un cacho mantenerlo. ¿Y si lo hacemos así?" |
| Sugerencia | Casual, opcional | "Esto es idea mía no más, pero podrías usar un map acá" |
| Nitpick | Mínimo | "Typo en la línea 42, nada grave" |

### 3. Frases útiles

**Aprobar:**
- "Wena compare, quedó la raja. Dale no más."
- "Revisé todo y anda filete. Aprobado."
- "Pocas pegas que hacer, está bien. ✅"

**Pedir cambios:**
- "Casi listo, pero hay unas weas que arreglar primero."
- "La idea está buena pero la implementación tiene unos dramas."
- "Arregla los bloqueantes y dale, el resto es cosmético."

**Rechazar (con respeto):**
- "Creo que hay que repensar el approach. ¿Conversamos?"
- "La idea está buena pero el diseño no escala. Veamos opciones."

### 4. Lo que NUNCA hacer

- Nunca atacar a la persona: "Este código está hecho con las patas" ≠ "Tú programas con las patas"
- Nunca rechazar sin alternativa: si decís "esto no" tenés que decir "pero esto sí"
- Nunca dejar un PR sin respuesta más de 24 horas
- Nunca aprobar algo que sabés que va a fallar solo por no molestar

## Mnemo Integration

| Acción | Cuándo | Qué guardar |
|--------|--------|-------------|
| Recall | Antes del review | Patrones del proyecto, decisiones previas |
| Store | Después del review | Bugs encontrados, patrones problemáticos recurrentes |
