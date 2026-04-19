# Server Actions

## Purpose

Handle form submissions and data mutations using Next.js Server Actions with progressive enhancement, optimistic updates, and proper revalidation.

## When to Use

- Processing form submissions without manual API routes
- Mutating server-side data (create, update, delete operations)
- Building forms that work without JavaScript (progressive enhancement)
- Implementing optimistic UI updates for responsive interactions

## Instructions

### Defining Server Actions

A Server Action is an async function marked with `"use server"`. It runs exclusively on the server:

```tsx
// In a separate file (recommended for reuse)
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function createPost(formData: FormData) {
  const title = formData.get("title") as string;
  const content = formData.get("content") as string;

  await db.post.create({ data: { title, content } });
  revalidatePath("/posts");
  redirect("/posts");
}
```

Or inline in a Server Component:

```tsx
export default function Page() {
  async function handleSubmit(formData: FormData) {
    "use server";
    // server-side logic
  }
  return <form action={handleSubmit}>...</form>;
}
```

### Form Action Pattern

Pass the Server Action directly to the form's `action` prop. This works without JavaScript:

```tsx
import { createPost } from "@/app/actions";

export default function NewPostPage() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

### useActionState for Form Feedback

Use `useActionState` to display validation errors and manage pending state:

```tsx
"use client";

import { useActionState } from "react";
import { createPost } from "@/app/actions";

type State = { errors?: { title?: string; content?: string }; message?: string };

export function PostForm() {
  const [state, action, isPending] = useActionState<State, FormData>(createPost, {});

  return (
    <form action={action}>
      <input name="title" required />
      {state.errors?.title && <p className="text-red-500">{state.errors.title}</p>}

      <textarea name="content" required />
      {state.errors?.content && <p className="text-red-500">{state.errors.content}</p>}

      <button type="submit" disabled={isPending}>
        {isPending ? "Creating..." : "Create Post"}
      </button>

      {state.message && <p>{state.message}</p>}
    </form>
  );
}
```

The Server Action must accept the previous state as its first argument when used with `useActionState`:

```tsx
"use server";

export async function createPost(prevState: State, formData: FormData): Promise<State> {
  const title = formData.get("title") as string;
  if (!title) return { errors: { title: "Title is required" } };

  await db.post.create({ data: { title } });
  revalidatePath("/posts");
  return { message: "Post created" };
}
```

### Progressive Enhancement

Forms with Server Actions work in three tiers:
1. **No JavaScript**: Form submits traditionally, full page reload with result.
2. **JavaScript loading**: Form submits traditionally, then hydrates.
3. **JavaScript loaded**: Form submits via fetch, no page reload, pending state shown.

This is automatic. No extra configuration needed.

### Optimistic Updates with useOptimistic

Show the expected result immediately while the server processes the mutation:

```tsx
"use client";

import { useOptimistic } from "react";
import { toggleLike } from "@/app/actions";

export function LikeButton({ liked, count }: { liked: boolean; count: number }) {
  const [optimistic, setOptimistic] = useOptimistic(
    { liked, count },
    (current, newLiked: boolean) => ({
      liked: newLiked,
      count: current.count + (newLiked ? 1 : -1),
    })
  );

  async function handleClick() {
    setOptimistic(!optimistic.liked);
    await toggleLike();
  }

  return (
    <form action={handleClick}>
      <button type="submit">
        {optimistic.liked ? "Unlike" : "Like"} ({optimistic.count})
      </button>
    </form>
  );
}
```

If the server action fails, React automatically reverts to the real state.

### Revalidation Strategies

After a mutation, tell Next.js what data is stale:

```tsx
"use server";

import { revalidatePath, revalidateTag } from "next/cache";

export async function updateProfile(formData: FormData) {
  await db.user.update({ ... });

  // Revalidate a specific path
  revalidatePath("/profile");

  // Revalidate all fetches tagged with "user"
  revalidateTag("user");

  // Revalidate a layout (revalidates all pages under it)
  revalidatePath("/dashboard", "layout");
}
```

### Security Considerations

Server Actions are public HTTP endpoints. Always validate and authorize:

```tsx
"use server";

import { auth } from "@/lib/auth";
import { z } from "zod";

const UpdateSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
});

export async function updatePost(prevState: State, formData: FormData) {
  const session = await auth();
  if (!session) throw new Error("Unauthorized");

  const result = UpdateSchema.safeParse(Object.fromEntries(formData));
  if (!result.success) {
    return { errors: result.error.flatten().fieldErrors };
  }

  const post = await db.post.findUnique({ where: { id: result.data.id } });
  if (post?.authorId !== session.user.id) throw new Error("Forbidden");

  await db.post.update({ where: { id: post.id }, data: result.data });
  revalidatePath(`/posts/${post.id}`);
  return { message: "Updated" };
}
```

### Non-Form Usage

Server Actions can be called from event handlers and effects too:

```tsx
"use client";

import { trackView } from "@/app/actions";

export function Article({ id, content }: Props) {
  useEffect(() => {
    trackView(id); // fire-and-forget server action
  }, [id]);

  return <article>{content}</article>;
}
```

## Examples

**Bad** -- manual API route for a simple form:
```tsx
// app/api/posts/route.ts
export async function POST(req: Request) { ... }

// component: fetch("/api/posts", { method: "POST", body: ... })
```

**Good** -- Server Action, works without JS, has validation:
```tsx
<form action={createPost}>
  <input name="title" required />
  <SubmitButton />
</form>
```

## Validation

- Server Actions are in files with `"use server"` at the top or marked inline
- Actions used with `useActionState` accept `(prevState, formData)` signature
- All Server Actions validate input (Zod or equivalent) and check authorization
- `revalidatePath` or `revalidateTag` is called after every mutation
- Forms use the `action` prop for progressive enhancement, not `onSubmit` with `preventDefault`
- Optimistic updates use `useOptimistic` and automatically revert on failure
- No sensitive logic relies solely on client-side checks
