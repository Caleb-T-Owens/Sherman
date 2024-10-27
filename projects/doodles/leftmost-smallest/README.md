# leftmost-smallest

This was a small puzzle I saw on linkedin which I solved in my head but didn't
actually write a solution down.

## The problem:

You're given some array of positive integers: `[5, 4, 2, 5, 3, 4, 6]`

For each of the elements in the array, you need to find the left most entry
which is smaller than itself.

For the example array, the solution would be `[-1, -1, -1, 4, 2, 2, 5]`.
`-1` is used if there is no entry to the left which is smaller.

## Running

To install dependencies:

```bash
bun install
```

To run:

```bash
bun run index.ts
```
