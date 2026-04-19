# App Router

## Purpose

Structure Next.js 15 applications using App Router file conventions, route groups, parallel routes, and intercepting routes for organized, scalable routing.

## When to Use

- Setting up page, layout, loading, and error boundaries
- Organizing routes without affecting URL structure
- Building modal patterns or split-view UIs with parallel routes
- Intercepting navigation for inline previews

## Instructions

### File Conventions

Every segment folder can contain these special files:

| File | Purpose | Renders |
|------|---------|---------|
| `page.tsx` | Unique UI for this route segment | Required to make route accessible |
| `layout.tsx` | Shared wrapper, preserves state across navigations | Wraps `page` and child layouts |
| `loading.tsx` | Instant loading UI (wraps page in `<Suspense>`) | While page is streaming |
| `error.tsx` | Error boundary for this segment and children | On uncaught error |
| `not-found.tsx` | UI for `notFound()` calls | When resource is missing |
| `template.tsx` | Like layout but re-mounts on navigation | Rare: animations, per-nav state |
| `default.tsx` | Fallback for parallel route slots | When slot has no matching segment |

### Layout and Page Relationship

Layouts wrap their segment's page and all child segments. They do not re-render when navigating between child pages:

```
app/
  layout.tsx        # Root layout (required, includes <html> and <body>)
  page.tsx          # Home page (/)
  dashboard/
    layout.tsx      # Dashboard layout (sidebar, nav)
    page.tsx        # /dashboard
    settings/
      page.tsx      # /dashboard/settings (wrapped by dashboard layout)
```

```tsx
// app/dashboard/layout.tsx
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1">{children}</main>
    </div>
  );
}
```

### Dynamic Routes

```
app/
  users/
    [id]/
      page.tsx        # /users/123 -> params.id = "123"
    [...slug]/
      page.tsx        # /users/a/b/c -> params.slug = ["a", "b", "c"]
    [[...slug]]/
      page.tsx        # Optional catch-all: matches /users too
```

```tsx
// app/users/[id]/page.tsx
export default async function UserPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getUser(id);
  if (!user) notFound();
  return <UserProfile user={user} />;
}
```

In Next.js 15, `params` and `searchParams` are async and must be awaited.

### Route Groups

Organize files without affecting URLs. Wrap folder name in parentheses:

```
app/
  (marketing)/
    about/page.tsx       # /about
    pricing/page.tsx     # /pricing
    layout.tsx           # Shared marketing layout
  (app)/
    dashboard/page.tsx   # /dashboard
    settings/page.tsx    # /settings
    layout.tsx           # Shared app layout (with auth)
```

Use cases:
- Different layouts for different sections of the site
- Grouping related routes for code organization
- Separating authenticated from public routes

### Parallel Routes

Render multiple pages in the same layout simultaneously using named slots:

```
app/
  dashboard/
    @analytics/page.tsx
    @activity/page.tsx
    layout.tsx
    page.tsx
```

```tsx
// app/dashboard/layout.tsx
export default function Layout({
  children,
  analytics,
  activity,
}: {
  children: React.ReactNode;
  analytics: React.ReactNode;
  activity: React.ReactNode;
}) {
  return (
    <div>
      {children}
      <div className="grid grid-cols-2">
        {analytics}
        {activity}
      </div>
    </div>
  );
}
```

Each slot loads independently and can have its own `loading.tsx` and `error.tsx`. Provide `default.tsx` in each slot to handle unmatched routes during soft navigation.

### Intercepting Routes

Show a route's content in a different context (such as a modal) during soft navigation, while preserving the full page on hard navigation/refresh:

```
app/
  feed/
    page.tsx               # Feed page
    @modal/
      (..)photo/[id]/
        page.tsx           # Intercepts /photo/[id], shows as modal
      default.tsx
  photo/
    [id]/
      page.tsx             # Full photo page (hard navigation)
```

Interception conventions:
- `(.)` -- same level
- `(..)` -- one level up
- `(..)(..)` -- two levels up
- `(...)` -- from app root

### Loading and Error Boundaries

`loading.tsx` automatically wraps the page in `<Suspense>`:

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return <DashboardSkeleton />;
}
```

`error.tsx` must be a Client Component:

```tsx
"use client";

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

### Metadata

Export `metadata` or `generateMetadata` from pages and layouts:

```tsx
export const metadata: Metadata = {
  title: "Dashboard",
  description: "View your analytics and activity",
};

// Dynamic metadata
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);
  return { title: product.name, description: product.summary };
}
```

## Examples

**Bad** -- everything in one flat folder, no layouts:
```
app/
  dashboard-page.tsx
  dashboard-settings-page.tsx
  dashboard-layout-wrapper.tsx
```

**Good** -- nested segments with proper conventions:
```
app/
  dashboard/
    layout.tsx
    page.tsx
    loading.tsx
    error.tsx
    settings/
      page.tsx
```

## Validation

- Root layout exists at `app/layout.tsx` with `<html>` and `<body>` tags
- Every accessible route has a `page.tsx` file
- `error.tsx` files include `"use client"` directive
- Route groups use parentheses and do not affect URL paths
- Parallel route slots have `default.tsx` fallbacks
- `params` and `searchParams` are awaited (Next.js 15 async requirement)
- `loading.tsx` is used instead of manual `<Suspense>` at route level
- Metadata is defined via `metadata` export or `generateMetadata` function
