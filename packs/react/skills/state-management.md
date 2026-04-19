# State Management

## Purpose

Choose the right state management approach for each use case, avoiding over-engineering while keeping state predictable and performant.

## When to Use

- Deciding where state should live (local, shared, server, URL)
- Evaluating whether a state library is necessary
- Managing server cache state versus UI state
- Synchronizing state with the URL for shareable views

## Instructions

### State Categories

Every piece of state falls into one of these categories. Each has an ideal solution:

| Category | Description | Best Approach |
|----------|-------------|---------------|
| **Local UI** | Toggle, input value, open/closed | `useState` / `useReducer` |
| **Shared UI** | Theme, sidebar state, auth | Context or Zustand |
| **Server cache** | API data, database records | TanStack Query / SWR |
| **URL state** | Filters, pagination, search | `useSearchParams` / `nuqs` |
| **Form state** | Field values, validation, submission | React 19 actions / `react-hook-form` |

### Decision Tree

```
Is this state from a server/API?
  YES -> TanStack Query or Server Components
  NO -> Is it shareable via URL?
    YES -> URL search params
    NO -> Is it used by 2+ unrelated components?
      YES -> Zustand (simple) or Context (small scope)
      NO -> useState / useReducer (keep it local)
```

### Local State: useState and useReducer

Default to local state. Lift only when a sibling or distant component actually needs it.

```tsx
function SearchInput() {
  const [query, setQuery] = useState("");
  return <input value={query} onChange={e => setQuery(e.target.value)} />;
}
```

### Context: Scoped Shared State

Use Context for state that a subtree needs but the whole app does not. Pair it with `useReducer` for complex updates:

```tsx
const CartContext = createContext<CartContextType | null>(null);

function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, dispatch] = useReducer(cartReducer, []);
  return (
    <CartContext value={{ items, dispatch }}>
      {children}
    </CartContext>
  );
}

function useCart() {
  const ctx = use(CartContext);
  if (!ctx) throw new Error("useCart must be inside CartProvider");
  return ctx;
}
```

Context pitfall: every consumer re-renders when the context value changes. Split contexts by update frequency (separate `CartItems` from `CartDispatch`).

### Zustand: Lightweight Global State

When Context re-renders too much or state is truly global across unrelated trees:

```tsx
import { create } from "zustand";

interface AppStore {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
}

const useAppStore = create<AppStore>((set) => ({
  sidebarOpen: false,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}));

// Components subscribe to slices -- only re-render when their slice changes
function Sidebar() {
  const open = useAppStore((s) => s.sidebarOpen);
  if (!open) return null;
  return <nav>...</nav>;
}
```

Zustand advantages over Context: selector-based rendering, no provider nesting, works outside React, tiny bundle (< 1KB).

### Jotai: Atomic State

When you need many independent pieces of shared state without a single store:

```tsx
import { atom, useAtom } from "jotai";

const countAtom = atom(0);
const doubleAtom = atom((get) => get(countAtom) * 2); // derived

function Counter() {
  const [count, setCount] = useAtom(countAtom);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### Server State: TanStack Query

API data is not UI state. It is a cache of remote data with its own lifecycle:

```tsx
function UserList() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["users"],
    queryFn: () => fetch("/api/users").then(r => r.json()),
    staleTime: 5 * 60 * 1000,   // fresh for 5 minutes
  });

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} />;
  return <ul>{data.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

TanStack Query handles caching, background refetch, deduplication, optimistic updates, and pagination. Do not replicate this with `useEffect` + `useState`.

### URL State

Filters, sort order, pagination, and search queries belong in the URL so views are shareable and bookmarkable:

```tsx
"use client";
import { useSearchParams } from "next/navigation";

function Filters() {
  const searchParams = useSearchParams();
  const category = searchParams.get("category") ?? "all";

  function setCategory(value: string) {
    const params = new URLSearchParams(searchParams);
    params.set("category", value);
    window.history.replaceState(null, "", `?${params}`);
  }

  return <Select value={category} onChange={setCategory} />;
}
```

For type-safe URL state with validation, consider `nuqs` (Next.js) which provides `useQueryState` with Zod schemas.

## Examples

**Bad** -- global Redux store for a single form:
```tsx
dispatch(setFormField("email", value));
```

**Good** -- local state for the form, server state for the data:
```tsx
const [email, setEmail] = useState("");
const { data } = useQuery({ queryKey: ["user"], queryFn: fetchUser });
```

## Validation

- Server/API data uses TanStack Query or Server Components, not `useState` + `useEffect`
- URL-dependent state (filters, search, pagination) is in search params, not component state
- Context is split by update frequency to avoid unnecessary re-renders
- No state management library is used for state that could be local `useState`
- Zustand selectors are used to prevent full-store re-renders
- Form state uses React 19 actions or a form library, not manual `useState` per field
