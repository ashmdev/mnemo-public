# Server Components

## Purpose

Leverage React Server Components (RSC) to fetch data on the server, reduce client bundle size, and stream UI progressively with Suspense boundaries.

## When to Use

- Fetching data that does not require client interactivity
- Rendering pages where most of the UI is static or read-only
- Reducing JavaScript shipped to the browser
- Streaming content progressively for faster perceived load times

## Instructions

### The Server/Client Mental Model

By default, every component in the App Router is a **Server Component**. It runs only on the server, has zero impact on client bundle size, and can directly access databases, file systems, or environment secrets.

A component becomes a **Client Component** only when you add `"use client"` at the top of its file. This is a boundary declaration: everything imported into that file also becomes part of the client bundle.

### When to Use Server Components

- Data fetching (database queries, API calls, file reads)
- Rendering markdown, syntax highlighting, or other heavy transforms
- Accessing backend resources (environment variables, secrets, file system)
- Components that display data without user interaction

### When to Use Client Components

- Event handlers (`onClick`, `onChange`, `onSubmit`)
- Hooks (`useState`, `useEffect`, `useRef`, custom hooks)
- Browser-only APIs (`localStorage`, `IntersectionObserver`, `navigator`)
- Interactive UI (modals, dropdowns, drag-and-drop, animations)

### The "use client" Boundary

```tsx
"use client";

import { useState } from "react";

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

Rules for the boundary:
- Place `"use client"` as high as it needs to be, but no higher. Push it down to the smallest interactive leaf.
- A Server Component can import and render a Client Component. The reverse is not true for direct imports -- but you can pass Server Components as `children` props to Client Components.
- Never put `"use client"` on a layout or page unless the entire page is interactive.

### Composition Pattern: Server Wrapping Client

```tsx
// page.tsx (Server Component)
import { Sidebar } from "./sidebar";  // Client Component
import { fetchNavItems } from "@/lib/data";

export default async function Layout({ children }) {
  const items = await fetchNavItems();
  return (
    <Sidebar items={items}>   {/* data fetched on server, passed as props */}
      {children}
    </Sidebar>
  );
}
```

### Data Fetching in Server Components

Server Components can be `async` and directly `await` data:

```tsx
export default async function UserProfile({ params }) {
  const user = await db.user.findUnique({ where: { id: params.id } });
  if (!user) notFound();
  return (
    <section>
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </section>
  );
}
```

No `useEffect`. No `useState` for loading. No client-side fetching library required.

### Streaming with Suspense

Wrap slow parts in `<Suspense>` so the shell loads instantly while heavy sections stream in:

```tsx
import { Suspense } from "react";

export default function Dashboard() {
  return (
    <main>
      <h1>Dashboard</h1>
      <Suspense fallback={<SkeletonChart />}>
        <AnalyticsChart />       {/* async server component, streams when ready */}
      </Suspense>
      <Suspense fallback={<SkeletonTable />}>
        <RecentOrders />
      </Suspense>
    </main>
  );
}
```

Each `<Suspense>` boundary streams independently. Place them around each independently-loadable section, not around the entire page.

### What Not to Pass Across the Boundary

Server-to-client props must be serializable. You cannot pass:
- Functions (event handlers, callbacks)
- Class instances
- Symbols, Maps, Sets
- JSX elements are fine -- React serializes them

## Examples

**Bad** -- entire page is a Client Component:
```tsx
"use client";
export default function Page() {
  const [data, setData] = useState(null);
  useEffect(() => { fetch("/api/data").then(...) }, []);
}
```

**Good** -- Server Component fetches, Client Component handles interaction:
```tsx
// page.tsx (server)
export default async function Page() {
  const data = await getData();
  return <InteractiveTable data={data} />;
}

// interactive-table.tsx
"use client";
export function InteractiveTable({ data }) {
  const [sorted, setSorted] = useState(data);
  // sorting, filtering logic
}
```

## Validation

- Server Components have no `"use client"` directive and no hooks or event handlers
- `"use client"` boundary is as deep in the tree as possible
- Data fetching happens in Server Components, not via `useEffect` in Client Components
- `<Suspense>` boundaries wrap each independent async section
- Props crossing the server/client boundary are serializable (no functions, no class instances)
- No sensitive data (API keys, secrets) is passed to Client Components
