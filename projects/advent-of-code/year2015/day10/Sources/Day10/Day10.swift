// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

enum StuffBroke: Error {
    case unknown
}

@main
@available(macOS 26, *)
struct Day10 {
    static func main() throws {
        // let string = try String(contentsOfFile: "./input.txt")

        var string = "1321131112"

        for _ in 0..<50 {
            let rle = rle(string: string)
            string = encode(rle: rle)
        }

        print(string.count)
    }
}

func rle(string: String) -> [(Character, Int)] {
    var output: [(Character, Int)] = []

    guard var currentSymbol: Character = string.first else {
        return []
    }
    var count = 0

    for char in string {
        if currentSymbol == char {
            count += 1
        } else {
            output.append((currentSymbol, count))
            currentSymbol = char
            count = 1
        }
    }
    output.append((currentSymbol, count))

    return output
}

func encode(rle: [(Character, Int)]) -> String {
    var str = ""

    for (term, count) in rle {
        str.append(String(count))
        str.append(term)
    }

    return str
}
