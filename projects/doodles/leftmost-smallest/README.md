# leftmost-smallest

This was a small puzzle I saw on linkedin which I solved in my head but didn't
actually write a solution down.

## The problem:

You're given some array of positive integers: `[5, 4, 2, 5, 3, 4, 6]`

For each of the elements in the array, you need to find the left most entry
which is smaller than itself.

For the example array, the solution would be `[-1, -1, -1, 4, 2, 2, 5]`.
`-1` is used if there is no entry to the left which is smaller.

## My solution

```ts
function leftMost(input: number[]) {
  const numberStack: number[] = [];
  const output = [];

  function findLeftestSmallest(n: number) {
    for (const entry of numberStack) {
      if (entry < n) {
        return entry;
      }
    }

    return -1;
  }

  for (const n of input) {
    const leftMostSmallest = findLeftestSmallest(n);

    if (leftMostSmallest === -1) {
      numberStack.push(n);
    }

    output.push(leftMostSmallest);
  }

  return output;
}
```

My solution with it's nested for loops actually runs in O(n) time.

I achieve this by making use of a variable to keep track of all of the smallest
left-most values. This means that rather than itterating over the whole array
in my inner loop, I can actually loop over this much smaller subset.

How much smaller is this subset? Well... it's length is `min(N, M)` where N is
the length of the input array, and M is the maximum integer for your number
datatype. This is because entry must be smaller than the last item in this array for it to be inserted; ensuring that there will never be a repeated digit in the
array.

As such, this means that our big-O for the worst case time complexity is
`O(N * min(N, M))`. However, because `M` is a constant value, we can simplify
the worst case to just `O(N)`.

## Running

To install dependencies:

```bash
bun install
```

To run:

```bash
bun run index.ts
```
