# Skill: Standup Chileno

## Propósito

Generar reportes de standup concisos y útiles para equipos chilenos.
El formato es rápido, honesto y al grano — como un buen standup presencial.

## Cuándo usar

Al inicio de cada sesión de trabajo o cuando el equipo pide status update.

## Instrucciones

### 1. Formato del standup

```
## 🧉 Standup — [fecha]

### ✅ Lo que hice ayer
- [tarea completada, con contexto breve]
- [otra tarea]

### 🔨 Lo que voy a hacer hoy
- [tarea principal del día]
- [tarea secundaria]

### 🚧 Bloqueos / Dramas
- [si hay algo que te tiene parado, decirlo acá]
- [si no hay: "Todo piola, sin bloqueos"]

### 💡 Dato pa'l equipo
- [algo que descubriste que puede servir a otros — opcional]
```

### 2. Ejemplo real

```
## 🧉 Standup — 2026-03-25

### ✅ Lo que hice ayer
- Terminé el refactor del config.yaml — quedó con 8 secciones bien ordenadas
- Arreglé 6 bugs de tenant isolation en el PG adapter (security fix)
- Dejé los hooks de Claude Code andando (4/4 verificados)

### 🔨 Lo que voy a hacer hoy
- Implementar el pack chilean-dev para el marketplace
- Testear el real-time sync E2E entre 2 instancias
- Empezar a preparar el CI/CD pipeline

### 🚧 Bloqueos / Dramas
- Todo piola, sin bloqueos

### 💡 Dato pa'l equipo
- Descubrí que el `Get()` del PG adapter no tenía tenant_id en el WHERE.
  Si alguien tiene otro adapter, revísenlo po.
```

### 3. Reglas del standup

- **Máximo 2 minutos** de lectura — si es más largo, estás contando de más
- **Honesto** — si ayer no avanzaste, decirlo: "Ayer estuve pegado con X"
- **Bloqueos reales** — "no sé cómo hacer X" es un bloqueo válido, pedir ayuda no es debilidad
- **Sin juicios** — el standup es información, no evaluación de desempeño
- **El dato pa'l equipo** es el MVP de knowledge sharing — úsalo

### 4. Fuente de datos

Usa `mem_search` y `mem_context` para reconstruir lo que hiciste:

```
mem_context(project="mnemo")  → sesiones recientes y memorias
mem_search("ayer", limit=10)  → lo que se guardó ayer
```

El standup se genera automáticamente desde las memorias de Mnemo.
Eso es dogfooding: Mnemo recuerda lo que hiciste para que no tengas que hacerlo tú.

## Mnemo Integration

| Acción | Cuándo | Qué guardar |
|--------|--------|-------------|
| Recall | Al generar standup | Sesiones y memorias de las últimas 24h |
| Store | Después del standup | El standup como memoria tipo "learning" |
