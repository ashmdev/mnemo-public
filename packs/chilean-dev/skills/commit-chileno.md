# Skill: Commits Bilingües

## Propósito

Escribir commits que sigan conventional commits pero con descripciones bilingües
que el equipo chileno entienda al tiro.

## Cuándo usar

Siempre que se haga commit en un proyecto con equipo hispanohablante.

## Instrucciones

### 1. Formato

```
<type>(<scope>): <descripción en inglés corta>

<cuerpo en chileno explicando el por qué>

Co-Authored-By: ...
```

### 2. Ejemplos

```
fix(auth): prevent JWT expiration race condition

Se estaba produciendo un cagazo cuando dos requests llegaban al mismo
tiempo con un token a punto de expirar. Ahora el refresh es atómico
y no debería pasar más.

Testeado con 100 requests concurrentes y no se cayó ni una vez.
```

```
feat(search): add team-scoped federated search

Los cabros del equipo ahora pueden buscar en las memorias de todos
usando sync_scope=team. Usa RRF pa mergear resultados locales y cloud.
Si el cloud se cae, retorna los locales no más — piola.
```

```
refactor(config): restructure flat config into hierarchical sections

El config estaba todo plano y era un cacho encontrar las cosas.
Ahora tiene secciones: identity, memory, search, team, privacy.
Backward compatible con el formato viejo.
```

### 3. Types en español (para referencia del equipo)

| Type | Significado | Cuándo |
|------|------------|--------|
| feat | Feature nueva | Funcionalidad que no existía |
| fix | Arreglo | Bug corregido |
| refactor | Refactoreo | Mismo comportamiento, mejor código |
| docs | Documentación | Solo docs, no código |
| test | Tests | Solo tests, no código productivo |
| chore | Mantenimiento | Dependencies, configs, CI |
| perf | Performance | Optimización medible |
| security | Seguridad | Fix de vulnerabilidad |

### 4. Reglas

- Título SIEMPRE en inglés (es la convención universal, los tools lo parsean)
- Cuerpo puede ser en chileno — es para el equipo, no para las máquinas
- Si el commit arregla un cagazo, explicar QUÉ pasaba y POR QUÉ
- Si es feature, explicar para QUÉ sirve desde el punto de vista del usuario
- No usar "misc", "changes", "update" — ser específico

## Mnemo Integration

| Acción | Cuándo | Qué guardar |
|--------|--------|-------------|
| Store | Después de cada commit | Patrón de commit para referencia futura |
