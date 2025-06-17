import { useEffect, useState } from "react";
import { BehaviorSubject, Observable } from "rxjs";

export type ReadonlyBehaviorSubject<T> = Omit<BehaviorSubject<T>, 'next'>

export function useObservable<T>(observable: Observable<T>) {
    const [value, setValue] = useState<T | undefined>();

    useEffect(() => {
        const subscription = observable.subscribe(setValue);
        return () => subscription.unsubscribe();
    }, [observable]);

    return value;
}

export function useSubject<T>(subject: ReadonlyBehaviorSubject<T>) {
    const [value, setValue] = useState<T>(subject.getValue());

    useEffect(() => {
        const subscription = subject.subscribe(setValue);
        return () => subscription.unsubscribe();
    }, [subject]);

    return value;
}