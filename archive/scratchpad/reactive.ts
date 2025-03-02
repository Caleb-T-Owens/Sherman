type Reactive<T> = { current: T };

function reactive<T>(fn: () => T): Reactive<T> {
    return {
        get current() {
            return fn();
        },
    };
}

function foo(asdf: Reactive<number>) {
    return reactive(() => asdf.current);
}
