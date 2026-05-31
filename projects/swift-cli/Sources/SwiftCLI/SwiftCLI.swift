// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct SwiftCLI {
    static func main() {
        print("Hello, world!")

        let foo = myFunction(foo: 12)

        print(foo)
    }
}

func myFunction(foo: Int) -> Int {
    foo * 2
}
