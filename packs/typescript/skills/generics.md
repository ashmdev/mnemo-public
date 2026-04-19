# Generics

## Purpose

Write reusable, type-safe generic functions and types in TypeScript using constraints, inference, conditional types, and mapped types without over-engineering.

## When to Use

- Building utility functions that work across multiple types
- Creating type-safe wrappers, containers, or adapters
- Deriving new types from existing ones programmatically
- Extracting types from function return values, promise results, or object shapes

## Instructions

### Generic Function Basics

A generic captures a type from the call site and threads it through the function signature:

```ts
function first<T>(items: T[]): T | undefined {
  return items[0];
}

const n = first([1, 2, 3]);       // number | undefined
const s = first(["a", "b"]);      // string | undefined
```

TypeScript infers `T` from the argument. Avoid specifying it explicitly unless inference fails.

### Constraints with extends

Restrict what `T` can be:

```ts
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { name: "Ada", age: 36 };
getProperty(user, "name");  // string
getProperty(user, "email"); // Compile error: "email" not in keyof typeof user
```

Common constraints:
- `T extends string | number` -- primitives
- `T extends { id: string }` -- structural shape
- `K extends keyof T` -- valid keys of an object
- `T extends (...args: any[]) => any` -- callable

### The infer Keyword

Extract types from within other types using `infer` in conditional types:

```ts
// Extract return type of a function
type ReturnOf<T> = T extends (...args: any[]) => infer R ? R : never;

// Extract the resolved type of a promise
type Awaited<T> = T extends Promise<infer U> ? Awaited<U> : T;

// Extract array element type
type ElementOf<T> = T extends (infer E)[] ? E : never;
```

`infer` works only inside the true branch of a conditional type. Think of it as pattern matching.

### Conditional Types

Branch types based on conditions:

```ts
type IsString<T> = T extends string ? true : false;

// Distributive: when T is a union, the conditional applies to each member
type NonNullable<T> = T extends null | undefined ? never : T;
// NonNullable<string | null> = string
```

Distributive behavior applies when the checked type is a naked type parameter. Wrap in `[T]` to prevent distribution if needed:

```ts
type IsUnion<T> = [T] extends [infer U] ? ([U] extends [T] ? false : true) : never;
```

### Mapped Types

Transform every property of a type:

```ts
// Make all properties optional
type Partial<T> = { [K in keyof T]?: T[K] };

// Make all properties readonly
type Readonly<T> = { readonly [K in keyof T]: T[K] };

// Remap keys with `as`
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

// { getName: () => string; getAge: () => number }
type UserGetters = Getters<{ name: string; age: number }>;
```

### Practical Generic Patterns

**Type-safe event emitter:**

```ts
type EventMap = {
  userLogin: { userId: string };
  itemAdded: { itemId: string; quantity: number };
};

class Emitter<T extends Record<string, unknown>> {
  private handlers = new Map<keyof T, Set<(payload: any) => void>>();

  on<K extends keyof T>(event: K, handler: (payload: T[K]) => void) {
    if (!this.handlers.has(event)) this.handlers.set(event, new Set());
    this.handlers.get(event)!.add(handler);
  }

  emit<K extends keyof T>(event: K, payload: T[K]) {
    this.handlers.get(event)?.forEach(fn => fn(payload));
  }
}

const bus = new Emitter<EventMap>();
bus.on("userLogin", (p) => console.log(p.userId)); // p is { userId: string }
bus.emit("itemAdded", { itemId: "x", quantity: 2 }); // type-checked payload
```

**Builder pattern with chained generics:**

```ts
class QueryBuilder<T extends Record<string, unknown>> {
  private filters: Partial<T> = {};

  where<K extends keyof T>(key: K, value: T[K]): this {
    this.filters[key] = value;
    return this;
  }

  build(): Partial<T> {
    return { ...this.filters };
  }
}
```

### Avoiding Over-Engineering

Do not use generics when a concrete type is sufficient. Generics add cognitive load:

```ts
// Over-engineered: T is always string here
function greet<T extends string>(name: T): string { return `Hello ${name}`; }

// Just use the concrete type
function greet(name: string): string { return `Hello ${name}`; }
```

Rules of thumb:
- If `T` appears only once in the signature, you probably do not need it.
- If the generic has more than 3 type parameters, reconsider the design.
- If you need a comment to explain what the generic does, it may be too complex.

### Built-in Utility Types

Know these before building your own:

| Type | Purpose |
|------|---------|
| `Partial<T>` | All properties optional |
| `Required<T>` | All properties required |
| `Readonly<T>` | All properties readonly |
| `Pick<T, K>` | Subset of properties |
| `Omit<T, K>` | All except named properties |
| `Record<K, V>` | Object with keys K and values V |
| `Extract<T, U>` | Members of T assignable to U |
| `Exclude<T, U>` | Members of T not assignable to U |
| `ReturnType<T>` | Return type of function type |
| `Parameters<T>` | Tuple of parameter types |

## Examples

**Bad** -- untyped, no inference:
```ts
function merge(a: any, b: any) { return { ...a, ...b }; }
```

**Good** -- generic with proper constraints:
```ts
function merge<A extends object, B extends object>(a: A, b: B): A & B {
  return { ...a, ...b };
}
```

## Validation

- Generic type parameters are constrained (`extends`) to the narrowest useful bound
- `infer` is used for type extraction instead of manual type assertions
- No generic has more than 3 type parameters without strong justification
- Built-in utility types (`Pick`, `Omit`, `Record`, etc.) are used before custom mapped types
- Generics that appear only once in a signature are replaced with concrete types
- Conditional types with unions handle distributive behavior intentionally
