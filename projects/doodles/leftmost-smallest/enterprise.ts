interface LeftmostListFinder {
  findLeftmosts(input: number[]): number[];
}

export class GeneralLeftmostListFinder implements LeftmostListFinder {
  readonly #orderedLookupFactory: OrderedLookupFactory;

  constructor(orderedLookupFactory: OrderedLookupFactory) {
    this.#orderedLookupFactory = orderedLookupFactory;
  }

  findLeftmosts(input: number[]): number[] {
    const orderedLookup = this.#orderedLookupFactory.build();

    const output = input.map((n) => {
      const result = orderedLookup.lookup(n);

      if (result === -1) {
        orderedLookup.push(n);
      }

      return result;
    });

    return output;
  }
}

interface OrderedLookupFactory {
  build(): OrderedLookup;
}

export class LinearOrderedLookupFactory implements OrderedLookupFactory {
  build() {
    return new LinearOrderedLookup();
  }
}

interface OrderedLookup {
  /** Push a new smaller right number */
  push(n: number): void;

  /**
   * Find the number that is the next smallest
   *
   * Returns -1 if there is no smaller number
   */
  lookup(n: number): number;
}

class LinearOrderedLookup implements OrderedLookup {
  #lookupList: number[] = [];

  push(n: number) {
    this.#lookupList.push(n);
  }

  lookup(n: number) {
    for (const entry of this.#lookupList) {
      if (entry < n) {
        return entry;
      }
    }

    // Entry not found
    return -1;
  }
}
