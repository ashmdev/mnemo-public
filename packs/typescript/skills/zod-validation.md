# Zod Validation

## Purpose

Define runtime validation schemas with Zod that serve as the single source of truth for both TypeScript types and data validation across API boundaries, forms, and configuration.

## When to Use

- Validating API request/response payloads at runtime
- Parsing user input from forms before submission
- Validating environment variables and configuration at startup
- Defining shared schemas between frontend and backend
- Replacing hand-written validation logic with declarative schemas

## Instructions

### Schema-First Design

Define the Zod schema first, then derive the TypeScript type from it. Never maintain both independently:

```ts
import { z } from "zod";

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  email: z.string().email(),
  role: z.enum(["admin", "editor", "viewer"]),
  createdAt: z.coerce.date(),
});

// Derive the type -- always in sync with the schema
type User = z.infer<typeof UserSchema>;
```

### Parsing vs Assertion

Zod follows "parse, don't validate." Use `.parse()` to transform unknown data into typed data, or `.safeParse()` when you need to handle errors without exceptions:

```ts
// Throws ZodError on failure
const user = UserSchema.parse(untrustedData);

// Returns a discriminated union
const result = UserSchema.safeParse(untrustedData);
if (result.success) {
  console.log(result.data); // typed as User
} else {
  console.log(result.error.flatten());
}
```

Prefer `.safeParse()` at boundaries where errors are expected (user input, external APIs). Use `.parse()` where invalid data is a programmer bug (internal config, trusted sources).

### API Validation

Validate incoming requests in API route handlers:

```ts
const CreateOrderSchema = z.object({
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().positive(),
  })).min(1),
  shippingAddress: AddressSchema,
  couponCode: z.string().optional(),
});

type CreateOrderInput = z.infer<typeof CreateOrderSchema>;

// Next.js server action
export async function createOrder(formData: FormData) {
  const raw = Object.fromEntries(formData);
  const result = CreateOrderSchema.safeParse(raw);
  if (!result.success) {
    return { errors: result.error.flatten().fieldErrors };
  }
  return await db.order.create({ data: result.data });
}
```

### API Response Validation

Validate data coming from external APIs to catch contract changes early:

```ts
const WeatherResponseSchema = z.object({
  temperature: z.number(),
  conditions: z.string(),
  forecast: z.array(z.object({
    date: z.string(),
    high: z.number(),
    low: z.number(),
  })),
});

async function getWeather(city: string) {
  const res = await fetch(`https://api.weather.example/${city}`);
  const json = await res.json();
  return WeatherResponseSchema.parse(json); // fails fast if API changes
}
```

### Environment Variable Validation

Validate env vars at startup so missing config fails immediately, not at first use:

```ts
const EnvSchema = z.object({
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  API_SECRET: z.string().min(32),
  PORT: z.coerce.number().int().default(3000),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
});

export const env = EnvSchema.parse(process.env);
// Use env.DATABASE_URL with full type safety
```

### Schema Composition

Build complex schemas from smaller, reusable parts:

```ts
const AddressSchema = z.object({
  street: z.string().min(1),
  city: z.string().min(1),
  country: z.string().length(2),
  postalCode: z.string(),
});

const PersonSchema = z.object({
  name: z.string(),
  address: AddressSchema,
});

// Extend schemas
const EmployeeSchema = PersonSchema.extend({
  department: z.string(),
  startDate: z.coerce.date(),
});

// Pick / omit
const CreatePersonInput = PersonSchema.omit({ address: true });
const PersonName = PersonSchema.pick({ name: true });

// Merge two schemas
const FullProfile = PersonSchema.merge(PreferencesSchema);
```

### Transform and Preprocess

Transform data during parsing:

```ts
const SlugSchema = z.string().transform(s => s.toLowerCase().replace(/\s+/g, "-"));

const MoneySchema = z.object({
  amount: z.string().transform(s => Math.round(parseFloat(s) * 100)), // to cents
  currency: z.enum(["USD", "EUR", "GBP"]),
});
```

Use `.coerce` for common type coercions:

```ts
z.coerce.number()  // "42" -> 42
z.coerce.boolean() // "true" -> true
z.coerce.date()    // "2024-01-01" -> Date object
```

### Form Validation

Pair Zod with form libraries for consistent validation:

```ts
// With react-hook-form
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";

const LoginSchema = z.object({
  email: z.string().email("Enter a valid email"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(LoginSchema),
  });
  // errors.email?.message is typed and comes from the schema
}
```

### Discriminated Unions in Zod

```ts
const NotificationSchema = z.discriminatedUnion("type", [
  z.object({ type: z.literal("email"), address: z.string().email() }),
  z.object({ type: z.literal("sms"), phone: z.string() }),
  z.object({ type: z.literal("push"), deviceId: z.string().uuid() }),
]);
```

## Examples

**Bad** -- manual validation, type and logic diverge:
```ts
type User = { name: string; age: number };
function validate(u: unknown): User {
  if (typeof u !== "object") throw new Error("invalid");
  // 20 more lines of manual checks...
}
```

**Good** -- schema is the source of truth:
```ts
const UserSchema = z.object({ name: z.string(), age: z.number().int().positive() });
type User = z.infer<typeof UserSchema>;
const user = UserSchema.parse(data);
```

## Validation

- TypeScript types are derived from Zod schemas with `z.infer<>`, never maintained separately
- `.safeParse()` is used at user-facing boundaries; `.parse()` for internal/trusted data
- Environment variables are validated with Zod at application startup
- API request bodies are validated before processing
- External API responses are validated to detect contract changes
- Form validation uses `zodResolver` or equivalent integration, not manual error checking
- No hand-written type guards exist for shapes that Zod schemas already describe
