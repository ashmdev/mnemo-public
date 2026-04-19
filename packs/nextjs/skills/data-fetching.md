# Data Fetching

## Purpose

Fetch and cache data in Next.js 15 using Server Components, fetch cache semantics, `unstable_cache`, ISR, and on-demand revalidation for optimal performance.

## When to Use

- Loading data in Server Components without client-side fetch libraries
- Configuring cache behavior for different data freshness requirements
- Setting up Incremental Static Regeneration for high-traffic pages
- Invalidating cached data after mutations

## Instructions

### Server Component Data Fetching

Server Components are async. Fetch data directly without hooks or effects:

```tsx
export default async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const product = await getProduct(id);
  if (!product) notFound();

  return (
    <main>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <Price amount={product.price} />
    </main>
  );
}
```

You can call databases, ORMs, or internal services directly. No API route needed.

### Fetch Cache Behavior (Next.js 15)

In Next.js 15, `fetch()` requests are **not cached by default**. This is a change from Next.js 14. You must opt into caching explicitly:

```tsx
// No cache (default in Next.js 15)
const data = await fetch("https://api.example.com/data");

// Cache indefinitely (equivalent to static)
const data = await fetch("https://api.example.com/data", {
  cache: "force-cache",
});

// Cache with time-based revalidation
const data = await fetch("https://api.example.com/data", {
  next: { revalidate: 3600 }, // revalidate after 1 hour
});

// Cache with tag for on-demand revalidation
const data = await fetch("https://api.example.com/products", {
  next: { tags: ["products"] },
});
```

### Caching Non-Fetch Data with unstable_cache

For database queries, ORM calls, or any non-fetch async function, use `unstable_cache`:

```tsx
import { unstable_cache } from "next/cache";

const getCachedProduct = unstable_cache(
  async (id: string) => {
    return await db.product.findUnique({ where: { id } });
  },
  ["product"],              // cache key prefix
  {
    revalidate: 3600,       // seconds
    tags: ["products"],     // for on-demand revalidation
  }
);

export default async function Page({ params }: Props) {
  const { id } = await params;
  const product = await getCachedProduct(id);
  return <ProductView product={product} />;
}
```

The cache key is formed from the key prefix array plus the function arguments. Same arguments produce cache hits.

### Segment-Level Cache Configuration

Control caching at the route segment level with config exports:

```tsx
// Static page (cached at build time)
export const dynamic = "force-static";

// Always dynamic (never cached)
export const dynamic = "force-dynamic";

// Revalidate entire page every N seconds (ISR)
export const revalidate = 3600;

// Control dynamic params behavior
export const dynamicParams = true; // allow params not in generateStaticParams
```

### Incremental Static Regeneration (ISR)

Generate pages statically and regenerate them in the background after a time interval:

```tsx
// app/products/[id]/page.tsx

export const revalidate = 60; // regenerate every 60 seconds

export async function generateStaticParams() {
  const products = await db.product.findMany({ select: { id: true } });
  return products.map((p) => ({ id: p.id }));
}

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await db.product.findUnique({ where: { id } });
  if (!product) notFound();
  return <ProductView product={product} />;
}
```

Behavior:
1. Pages in `generateStaticParams` are built at deploy time.
2. Requests within `revalidate` seconds serve the cached version.
3. After `revalidate`, the next request triggers a background regeneration.
4. The stale page is served until the new one is ready (stale-while-revalidate).

### On-Demand Revalidation

Invalidate cached data immediately after a mutation:

```tsx
"use server";

import { revalidatePath, revalidateTag } from "next/cache";

export async function updateProduct(id: string, data: ProductInput) {
  await db.product.update({ where: { id }, data });

  // Option 1: Revalidate by path
  revalidatePath(`/products/${id}`);

  // Option 2: Revalidate by tag (more granular)
  revalidateTag("products");
  revalidateTag(`product-${id}`);
}
```

Tag-based revalidation is more precise. Tag your fetches and `unstable_cache` calls, then invalidate specific tags after mutations.

### Parallel Data Fetching

Avoid request waterfalls. Fetch independent data in parallel:

```tsx
export default async function Dashboard() {
  // Bad: sequential (waterfall)
  // const user = await getUser();
  // const orders = await getOrders();
  // const analytics = await getAnalytics();

  // Good: parallel
  const [user, orders, analytics] = await Promise.all([
    getUser(),
    getOrders(),
    getAnalytics(),
  ]);

  return (
    <div>
      <UserCard user={user} />
      <OrderList orders={orders} />
      <AnalyticsChart data={analytics} />
    </div>
  );
}
```

For independent sections that can stream, use `<Suspense>` instead of `Promise.all`:

```tsx
export default function Dashboard() {
  return (
    <div>
      <Suspense fallback={<Skeleton />}>
        <UserCard />         {/* each fetches its own data */}
      </Suspense>
      <Suspense fallback={<Skeleton />}>
        <OrderList />
      </Suspense>
    </div>
  );
}
```

### Request Deduplication

Next.js automatically deduplicates `fetch()` calls with the same URL and options within a single render pass. If a layout and page both fetch the same URL, only one network request is made.

For non-fetch functions, use React's `cache()` to deduplicate:

```tsx
import { cache } from "react";

export const getUser = cache(async (id: string) => {
  return await db.user.findUnique({ where: { id } });
});

// Called in layout and page -- only executes once per request
```

### Streaming and Loading States

Combine data fetching with streaming for the best user experience:

```tsx
// app/dashboard/page.tsx
export default async function Page() {
  const summary = await getDashboardSummary(); // fast query, no Suspense needed
  return (
    <main>
      <Summary data={summary} />
      <Suspense fallback={<ChartSkeleton />}>
        <SlowChart />          {/* streams in when ready */}
      </Suspense>
    </main>
  );
}
```

## Examples

**Bad** -- client-side fetching in a page that could be a Server Component:
```tsx
"use client";
export default function Page() {
  const [data, setData] = useState(null);
  useEffect(() => { fetch("/api/data").then(r => r.json()).then(setData); }, []);
}
```

**Good** -- Server Component with caching and streaming:
```tsx
export default async function Page() {
  const data = await getCachedData();
  return (
    <main>
      <DataView data={data} />
      <Suspense fallback={<Skeleton />}>
        <RelatedItems />
      </Suspense>
    </main>
  );
}
```

## Validation

- Data fetching happens in Server Components, not via `useEffect` in Client Components
- `fetch()` calls include explicit cache configuration (`cache`, `next.revalidate`, or `next.tags`)
- Non-fetch async operations use `unstable_cache` with tags and revalidation intervals
- Independent data requests are parallelized with `Promise.all` or separate `<Suspense>` boundaries
- `revalidatePath` or `revalidateTag` is called in every Server Action that mutates data
- `generateStaticParams` is defined for dynamic routes that can be pre-rendered
- React `cache()` is used to deduplicate non-fetch database calls within a render
- No request waterfalls exist where parallel fetching is possible
