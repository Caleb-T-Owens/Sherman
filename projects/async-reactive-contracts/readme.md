# Async Reactive Contracts

A common interface used when working with reactive types like RxJS's
Observables, Svelte stores, and Svelte effects is the curryed unsubscribe
pattern.

In order to recieve data from reactive you work with an interface like:
```ts
declare const subscribe: (cb: (v: unknown) => void) => () => void
```

The first time `subscribe` is called, the reactive type kicks into action and
triggers the start notifier inside the reactive. `subscribe` may be called
multiple times, but the start notifier won't be called again unless the
unsubscriber has been called an equal amount of times. Once all the unsubscribe
calls have been made in coorespondence to the subscribe calls, the reactive's
stop notifier gets called, and may perform some clean up.

In both Svelte and RxJS, the start and stop notifers are preferably implemented
as syncronus code because their lifetime is also managed syncronusly.

It begs the question, if I had a setup that was asynchronus, and had an
unsubscribe that depended on the result of the asyncronus action, how can I
safly manage it?

If you were going to build a reactive extension library from the ground up, you
might choose to build your interface to look like the following:
```ts
declare const subscribeAsync: (cb: (v: unknown) => void) => Promise<() => Promise<void>>
```

Doing so would allow the entire system to be async aware, and everything should
fall into place by default.

If you are in a syncronus environment like svelte, then consuming an interface
like `subscribeAsync` requires a little more care. For example, how would I tie
the lifecycle of `subscribeAsync` to that of a `$effect` block? The `$effect`
block expects it's stop notifier to be
returned immidiatly, but our unsubscriber is not ready yet.

## A simpler problem

Let's imagine we have some async function `() => Promise<void>` that we want to
be calling inside a syncronus environment. In the syncronus environment, the
function may be called many times, but we only want the action to be
re-performed after it has actually completed.

IE, if we had the following setup, we would expect the following output:
```ts
async function inner() {
    console.log("a")
    await sleep(1000)
    console.log("b")
}

const outer = makeSync(inner)

outer()
// A logged
outer()
// nothing happens
// 1000 ms elapses
// B logged
outer()
// A logged again
```

This is a problem very reminicent of debouncing and can be solved very simply
by defining `makeSync` as follows:
```ts
function makeSync(fn: () => Promise<void>): () => void {
    let working = false

    return () => {
        if (working) return
        working = true
        fn().then(() => {
            working = false
        })
    }
}
