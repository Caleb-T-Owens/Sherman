# Anylang 3

```
Composition:

fn1 fn2: (arg) => fn2(fn1(arg))

fn1 Fn2 fn3: Fn2(fn1(arg1), fn3(arg2))
fn1 Fn2: Fn2(fn1(arg1), arg2)
Fn2 fn3: Fn2(arg1, fn3(arg2))

fn1 Fn2 fn3 fn4: Fn2(fn1(arg1), fn4(fn3(arg2)))
fn1 Fn2 fn3 -> fn4: fn4(Fn2(fn1(arg1), fn3(arg2)))

Fn1 -> fn2: fn2(Fn1(arg1, arg2))

https://mlochbaum.github.io/BQN/doc/tacit.html#combinators

Atop:

g f: f(g(x))
g->f: f(g(x))
G->f: f(G(x, y))

Over:

g F g: F(g(x), g(y))
g=>F: F(g(x), g(y))

Before:
f~>G: G(f(x), x)
```
