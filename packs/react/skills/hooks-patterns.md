# Hooks Patterns

## Purpose

Write correct, composable React hooks that manage state, side effects, and external subscriptions following current best practices.

## When to Use

- Encapsulating reusable stateful logic across components
- Managing side effects with proper cleanup
- Choosing between useState, useReducer, and external state
- Subscribing to external data sources or browser APIs
- Using React 19's new `use()` hook for promises and context

## Instructions

### Custom Hook Rules

1. **Name starts with `use`.** This enables the linter to enforce Rules of Hooks.
2. **Extract when logic is shared** between two or more components, or when a component's hook logic becomes complex enough to test independently.
3. **Return explicit values.** Prefer `{ data, error, isLoading }` objects over arrays for hooks with many return values. Use tuples `[value, setter]` only for simple state-like hooks.

```tsx
function useDebounce<T>(value: T, delayMs: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);
  return debounced;
}
```

### useEffect Cleanup

Every effect that creates a subscription, timer, or listener must return a cleanup function:

```tsx
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal })
    .then(res => res.json())
    .then(setData)
    .catch(err => {
      if (err.name !== "AbortError") setError(err);
    });
  return () => controller.abort();
}, [url]);
```

Common cleanup needs:
- `clearTimeout` / `clearInterval`
- `controller.abort()` for fetch
- `observer.disconnect()` for IntersectionObserver / ResizeObserver
- `removeEventListener` for window/document listeners
- WebSocket `.close()`

### useEffect is Not for Data Fetching

In modern React, prefer these over `useEffect` for data:
- **Server Components** -- fetch on the server, no effect needed
- **Route loaders** (Next.js, Remix) -- data loads before render
- **TanStack Query / SWR** -- handles caching, deduplication, revalidation
- **React 19 `use()`** -- read a promise directly in render

Reserve `useEffect` for true side effects: DOM manipulation, analytics events, third-party library initialization.

### useState vs useReducer

**useState** when:
- State is a single value or simple object
- Updates are independent of each other
- Logic is straightforward

**useReducer** when:
- Multiple state values change together
- Next state depends on previous state in complex ways
- State transitions follow business rules you want to name

```tsx
type Action =
  | { type: "fetch" }
  | { type: "success"; data: Item[] }
  | { type: "error"; error: Error };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "fetch":   return { ...state, loading: true, error: null };
    case "success": return { loading: false, data: action.data, error: null };
    case "error":   return { loading: false, data: null, error: action.error };
  }
}
```

### useSyncExternalStore

Subscribe to external mutable sources (browser APIs, third-party stores) safely:

```tsx
function useOnlineStatus(): boolean {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener("online", callback);
      window.addEventListener("offline", callback);
      return () => {
        window.removeEventListener("online", callback);
        window.removeEventListener("offline", callback);
      };
    },
    () => navigator.onLine,       // client snapshot
    () => true                     // server snapshot
  );
}
```

Always provide the server snapshot (third argument) for SSR compatibility.

### React 19: use() Hook

`use()` reads a promise or context value directly in render. It can be called conditionally, unlike other hooks:

```tsx
import { use } from "react";

function UserName({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);  // suspends until resolved
  return <span>{user.name}</span>;
}

// Usage with Suspense
<Suspense fallback={<Spinner />}>
  <UserName userPromise={fetchUser(id)} />
</Suspense>
```

For context: `const theme = use(ThemeContext)` replaces `useContext(ThemeContext)` and works inside conditionals.

### useRef for Mutable Values

Use `useRef` for values that persist across renders without causing re-renders:

```tsx
const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

useEffect(() => {
  intervalRef.current = setInterval(tick, 1000);
  return () => clearInterval(intervalRef.current!);
}, []);
```

Never read or write `.current` during render for mutable refs. DOM refs are the exception.

## Examples

**Bad** -- effect without cleanup, fetch in effect:
```tsx
useEffect(() => {
  fetch(url).then(r => r.json()).then(setData);
}, [url]);
```

**Good** -- abort controller, or better, no effect at all:
```tsx
// Option A: Server Component (best)
const data = await getData();

// Option B: TanStack Query (client interactive)
const { data } = useQuery({ queryKey: ["items"], queryFn: getItems });
```

## Validation

- Every `useEffect` that subscribes or allocates returns a cleanup function
- `useEffect` is not used for data fetching when Server Components or query libraries are available
- Custom hooks start with `use` and contain no JSX
- `useSyncExternalStore` is used for external mutable sources, not `useEffect` + `useState`
- `useRef` mutations do not happen during render
- All hook calls are at the top level, not inside conditions or loops (except `use()` in React 19)
