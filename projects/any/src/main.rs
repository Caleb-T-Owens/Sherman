mod checking;
mod grammar;

fn main() {
    println!("Hello, world!");
}

#[cfg(test)]
mod test {
    use crate::grammar::g;

    #[test]
    fn basic_grammar() {
        let sample = "
// Number would initially be just a f32, but ideally it could be a
// typeclass.
//
// Funtions define the types that the tip of the stack should have, and
// how it expects to leave the stack.
def add(Number, Number -> Number)
    // Functions can only see the declared portion of the stack.
    +
end

def main(->)
    42 24 // push values onto the stack. Lines are evalued left to right (I'm not a criminal like uiwa)

    add // results in a stack containing just 66

    dup puts
    66
    == if
        \"it was 66\" puts
        44
    else
        23
    end
end
        ";

        match g::parse(sample) {
            Ok(ast) => {
                dbg!(ast);
            }
            Err(errs) => {
                for err in errs {
                    let segment = &sample[err.start..err.end];
                    println!(
                        "Treesitter got stuck around: {} to {}. At:\n{}",
                        err.start, err.end, segment
                    )
                }
            }
        };
    }
}
