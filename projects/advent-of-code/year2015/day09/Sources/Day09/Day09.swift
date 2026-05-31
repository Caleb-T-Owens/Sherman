// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

typealias Graph = [String: [(String, Int)]]

@main
@available(macOS 26, *)
struct Day09 {
    static func main() throws {
        let string = try String(contentsOfFile: "./input.txt")
        let lines = string.split(whereSeparator: \.isNewline)

        var graph: Graph = [:]

        for line in lines {
            let a = line.split(separator: " = ")
            guard let edgeWeight = Int(a[1]) else {
                return
            }
            let b = a[0].split(separator: " to ")
            let source = String(b[0])
            let destination = String(b[1])

            graph[source, default: []].append((destination, edgeWeight))
            graph[destination, default: []].append((source, edgeWeight))
        }

        let allPaths = graph.keys.flatMap { traverse(path: [$0], currentWeight: 0, graph: graph) }
        let shortestDistance = allPaths.max { $0.1 < $1.1 }?.1 ?? 0
        print(shortestDistance)
    }
}

// traverse([a], currentWeight: 0) -> all the possible paths
// traverse([a, b], currentWeight: partialWeight) -> all the possible paths
func traverse(path: [String], currentWeight: Int, graph: Graph) -> [([String], Int)] {
    if graph.keys.allSatisfy({ path.contains($0) }) {
        return [(path, currentWeight)]
    }

    if let lastElement = path.last {
        let out = graph[lastElement]?.filter { !path.contains($0.0) }.flatMap {
            traverse(path: path + [$0.0], currentWeight: currentWeight + $0.1, graph: graph)
        }
        return out ?? []
    }

    return []
}
