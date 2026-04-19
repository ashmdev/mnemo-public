# Type Safety

## Purpose

Maximize compile-time safety in TypeScript using strict mode, discriminated unions, exhaustive checks, branded types, and template literals to catch bugs before they reach runtime.

## When to Use

- Setting up or tightening a TypeScript project configuration
- Modeling domain types that must be mutually exclusive
- Preventing invalid states through the type system
- Distinguishing structurally identical types (IDs, currencies, units)

## Instructions

### Strict Mode

Enable all strict checks in `tsconfig.json`. This is non-negotiable for new projects:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

`strict: true` enables: `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitAny`, `noImplicitThis`, `alwaysStrict`, `useUnknownInCatchVariables`.

`noUncheckedIndexedAccess` makes array and record access return `T | undefined`, forcing you to handle missing values.

### Ban `any`

Use `unknown` instead of `any` when the type is genuinely not known. `unknown` forces you to narrow before use:

```ts
// Bad
function parse(input: any) { return input.name; }

// Good
function parse(input: unknown): string {
  if (typeof input === "object" && input !== null && "name" in input) {
    return (input as { name: string }).name;
  }
  throw new Error("invalid input");
}
```

Use ESLint rule `@typescript-eslint/no-explicit-any` to enforce this.

### Discriminated Unions

Model mutually exclusive states with a shared literal discriminant:

```ts
type Result<T> =
  | { status: "success"; data: T }
  | { status: "error"; error: Error }
  | { status: "loading" };
```

TypeScript narrows the type when you check the discriminant:

```ts
function handle(result: Result<User>) {
  switch (result.status) {
    case "success": return renderUser(result.data);
    case "error":   return renderError(result.error);
    case "loading": return renderSkeleton();
  }
}
```

### Exhaustive Checks

Ensure every variant is handled. If a new variant is added, the compiler catches the missing case:

```ts
function assertNever(value: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(value)}`);
}

function handle(result: Result<User>) {
  switch (result.status) {
    case "success": return renderUser(result.data);
    case "error":   return renderError(result.error);
    case "loading": return renderSkeleton();
    default:        return assertNever(result); // compile error if a case is missing
  }
}
```

Alternatively, use `satisfies never` in TypeScript 5+:

```ts
default: {
  const _: never = result;
  throw new Error(`Unhandled: ${_}`);
}
```

### Branded Types

Prevent mixing structurally identical types (two different ID types are both `string`):

```ts
type Brand<T, B extends string> = T & { readonly __brand: B };

type UserId = Brand<string, "UserId">;
type OrderId = Brand<string, "OrderId">;

function createUserId(id: string): UserId { return id as UserId; }
function createOrderId(id: string): OrderId { return id as OrderId; }

function getUser(id: UserId): User { ... }

const uid = createUserId("u_123");
const oid = createOrderId("o_456");

getUser(uid); // OK
getUser(oid); // Compile error: OrderId not assignable to UserId
```

Use branded types for: database IDs, currency amounts, validated strings, measurement units.

### Template Literal Types

Build string patterns at the type level:

```ts
type EventName = `on${Capitalize<"click" | "hover" | "focus">}`;
// "onClick" | "onHover" | "onFocus"

type CSSUnit = `${number}${"px" | "rem" | "em" | "%"}`;
// "16px", "1.5rem", etc.

type APIRoute = `/api/${string}`;
function fetchAPI(route: APIRoute): Promise<Response> { ... }
fetchAPI("/api/users");   // OK
fetchAPI("/users");        // Compile error
```

### Const Assertions

Preserve literal types with `as const`:

```ts
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ROLES)[number]; // "admin" | "editor" | "viewer"

const CONFIG = {
  maxRetries: 3,
  timeout: 5000,
} as const;
// type: { readonly maxRetries: 3; readonly timeout: 5000 }
```

### Utility Type Patterns

```ts
// Make specific fields required
type WithRequired<T, K extends keyof T> = T & Required<Pick<T, K>>;

// Deep readonly
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};
```

## Examples

**Bad** -- stringly typed, no compile-time safety:
```ts
function processEvent(type: string, payload: any) { ... }
```

**Good** -- discriminated union, exhaustive handling:
```ts
type AppEvent =
  | { type: "USER_LOGIN"; userId: string }
  | { type: "ITEM_ADDED"; itemId: string; quantity: number };

function processEvent(event: AppEvent) {
  switch (event.type) {
    case "USER_LOGIN": return handleLogin(event.userId);
    case "ITEM_ADDED": return handleItem(event.itemId, event.quantity);
    default: assertNever(event);
  }
}
```

## Validation

- `strict: true` and `noUncheckedIndexedAccess: true` are enabled in tsconfig
- No `any` types exist (enforced by ESLint rule)
- All union types use discriminated unions with a literal discriminant field
- Switch statements over unions include an exhaustive check (`assertNever` or `satisfies never`)
- Structurally identical IDs use branded types to prevent mixing
- `as const` is used for literal arrays and config objects that should not widen
