import {
  GeneralLeftmostListFinder,
  LinearOrderedLookupFactory,
} from "./enterprise";

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

console.log(leftMost([5, 4, 2, 5, 3, 4, 6]));

const linearOrderedLookupFactory = new LinearOrderedLookupFactory();
const generalLeftmostListFinder = new GeneralLeftmostListFinder(
  linearOrderedLookupFactory
);

console.log(generalLeftmostListFinder.findLeftmosts([5, 4, 2, 5, 3, 4, 6]));
