# Performance

## Purpose

Optimize React application performance using the React Compiler, code splitting, lazy loading, virtualization, and profiling tools.

## When to Use

- Reducing bundle size and initial load time
- Handling large lists or data-heavy UIs
- Diagnosing unnecessary re-renders
- Evaluating whether manual memoization is still needed

## Instructions

### React Compiler (React 19+)

The React Compiler automatically memoizes components, hooks, and expressions at build time. When it is enabled, you should not manually write `useMemo`, `useCallback`, or `React.memo` in new code.

**Setup**: The compiler is a Babel plugin. Add it to your build config:

```js
// babel.config.js
module.exports = {
  plugins: [["babel-plugin-react-compiler"]],
};
```

**What changes**:
- Components no longer re-render children when parent state changes unless props actually differ.
- Inline functions and objects are automatically stable -- no need for `useCallback` or `useMemo`.
- `React.memo` wrappers are unnecessary and can be removed during migration.

**When to keep manual memos**:
- The compiler cannot optimize code with side effects in render. Keep render functions pure.
- If you are not yet on the compiler, continue using `useMemo` for expensive computations and `React.memo` for stable-prop components.

### Code Splitting with Lazy Loading

Split route-level and heavy components so they are loaded on demand:

```tsx
import { lazy, Suspense } from "react";

const AdminDashboard = lazy(() => import("./admin-dashboard"));

function App() {
  return (
    <Suspense fallback={<PageSkeleton />}>
      <AdminDashboard />
    </Suspense>
  );
}
```

Split aggressively at route boundaries. Every page the user might not visit should be a separate chunk.

For named exports:

```tsx
const Chart = lazy(() =>
  import("./charts").then(mod => ({ default: mod.BarChart }))
);
```

### Dynamic Import for Heavy Libraries

Load large dependencies only when needed:

```tsx
async function handleExport() {
  const { exportToPDF } = await import("./pdf-export");
  await exportToPDF(data);
}
```

This keeps libraries like PDF generators, chart libraries, or syntax highlighters out of the initial bundle entirely.

### Virtualization for Large Lists

Rendering thousands of DOM nodes is slow regardless of React. Use windowing to render only visible items:

```tsx
import { useVirtualizer } from "@tanstack/react-virtual";

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 48,
  });

  return (
    <div ref={parentRef} style={{ height: 600, overflow: "auto" }}>
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map(row => (
          <div
            key={row.key}
            style={{
              position: "absolute",
              top: row.start,
              height: row.size,
              width: "100%",
            }}
          >
            {items[row.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

Use virtualization when lists exceed approximately 100 items or when row rendering is heavy.

### Image Optimization

- Use `next/image` (Next.js) or responsive `<picture>` elements with proper `srcSet`.
- Always specify `width` and `height` to prevent layout shift.
- Use `loading="lazy"` for below-fold images.
- Prefer modern formats: WebP or AVIF with JPEG fallback.

### Bundle Analysis

Identify what is making your bundle large:

```bash
# Next.js
ANALYZE=true next build

# Vite
npx vite-bundle-visualizer

# Generic webpack
npx webpack-bundle-analyzer stats.json
```

Look for:
- Duplicate dependencies (different versions of the same package)
- Large libraries that could be replaced (moment.js -> date-fns, lodash -> individual imports)
- Dead code that tree-shaking missed

### React Profiler

Use the React DevTools Profiler to find unnecessary re-renders:

1. Open React DevTools, click the Profiler tab.
2. Click record, interact with the UI, stop recording.
3. Look for components that re-rendered but produced the same output.
4. "Highlight updates" option visually shows re-rendering components.

Programmatic profiling:

```tsx
<Profiler id="sidebar" onRender={(id, phase, duration) => {
  if (duration > 16) {
    console.warn(`${id} slow render: ${duration}ms`);
  }
}}>
  <Sidebar />
</Profiler>
```

### Avoiding Common Performance Mistakes

- **Creating objects/arrays in render**: `style={{ color: "red" }}` creates a new object every render. With the compiler this is handled; without it, hoist to a constant.
- **Prop drilling through many layers**: Does not cause performance issues by itself, but signals a need for context or composition.
- **Premature optimization**: Measure first. Only optimize what the profiler shows is slow.

## Examples

**Bad** -- loads entire charting library upfront:
```tsx
import { BarChart } from "recharts"; // 200KB in initial bundle
```

**Good** -- lazy loads when user navigates to analytics:
```tsx
const BarChart = lazy(() => import("recharts").then(m => ({ default: m.BarChart })));
```

## Validation

- No `useMemo`, `useCallback`, or `React.memo` in projects with React Compiler enabled
- Route-level components use `lazy()` + `<Suspense>` for code splitting
- Lists with 100+ items use virtualization (`@tanstack/react-virtual` or similar)
- Bundle analyzer has been run and no duplicate or oversized dependencies exist
- `next/image` or responsive images are used with explicit dimensions
- React DevTools Profiler shows no unnecessary re-renders in critical paths
