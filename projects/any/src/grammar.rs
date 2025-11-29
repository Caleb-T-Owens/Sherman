// I don't love the nexted modules, ergo is _not_ nice.
#[rust_sitter::grammar("any")]
#[allow(unused)]
pub mod g {
    use rust_sitter::Spanned;

    #[rust_sitter::language]
    #[derive(Debug, Clone)]
    pub struct Program {
        #[rust_sitter::repeat]
        pub statements: Vec<Spanned<Statement>>,
    }

    #[derive(Debug, Clone)]
    pub enum Statement {
        Comment(Spanned<Comment>),
        Function(Spanned<Function>),
    }

    #[derive(Debug, Clone)]
    pub enum Expression {
        Literal(Spanned<Literal>),
        // Comments are also expressions? :D
        Comment(Spanned<Comment>),
        Identifier(Spanned<LowerIdentifier>),
        Operator(Spanned<Operator>),
        Conditional(Spanned<Conditional>),
    }

    #[derive(Debug, Clone)]

    pub struct Conditional {
        #[rust_sitter::leaf(text = "if")]
        _if: (),
        pub exps: Vec<Spanned<Expression>>,
        #[rust_sitter::optional]
        pub conditional_else: Option<Spanned<ConditionalElse>>,
        #[rust_sitter::leaf(text = "end")]
        _end: (),
    }

    #[derive(Debug, Clone)]
    pub struct ConditionalElse {
        #[rust_sitter::leaf(text = "else")]
        _else: (),
        pub exps: Vec<Spanned<Expression>>,
    }

    #[derive(Debug, Clone)]
    pub enum Literal {
        Number(Spanned<Number>),
        String(Spanned<StringT>),
        Boolean(Spanned<Boolean>),
    }

    #[derive(Debug, Clone)]
    pub struct Function {
        #[rust_sitter::leaf(text = "def")]
        _def: (),
        pub name: Spanned<LowerIdentifier>,
        pub signature: Spanned<FunctionSignature>,
        pub expressions: Vec<Spanned<Expression>>,
        #[rust_sitter::leaf(text = "end")]
        _end: (),
    }

    #[derive(Debug, Clone)]
    pub struct FunctionSignature {
        #[rust_sitter::leaf(text = "(")]
        _open: (),
        #[rust_sitter::delimited(
            #[rust_sitter::leaf(text = ",")]
            ()
        )]
        pub from: Vec<Spanned<UpperIdentifier>>,
        #[rust_sitter::leaf(text = "->")]
        _arrow: (),
        #[rust_sitter::delimited(
            #[rust_sitter::leaf(text = ",")]
            ()
        )]
        pub to: Vec<Spanned<UpperIdentifier>>,
        #[rust_sitter::leaf(text = ")")]
        _close: (),
    }

    #[derive(Debug, Clone)]
    #[rust_sitter::word]
    pub struct LowerIdentifier(
        #[rust_sitter::leaf(pattern = r"[a-z][a-zA-Z0-9]*", transform = |v| v.to_string())]
        pub  String,
    );

    #[derive(Debug, Clone)]
    #[rust_sitter::word]
    pub struct UpperIdentifier(
        #[rust_sitter::leaf(pattern = r"[A-Z][a-zA-Z0-9]*", transform = |v| v.to_string())]
        pub  String,
    );

    #[derive(Debug, Clone)]
    pub struct Number(
        #[rust_sitter::leaf(pattern = r"\d+(\.\d+)?", transform = |v| v.parse().unwrap())] pub f64,
    );

    #[derive(Debug, Clone)]
    pub struct StringT {
        #[rust_sitter::leaf(text = "\"")]
        _open: (),
        #[rust_sitter::leaf(pattern = r#"[^"]*"#, transform = |v| v.to_string())]
        content: String,
        #[rust_sitter::leaf(text = "\"")]
        _close: (),
    }

    #[derive(Debug, Clone)]
    pub struct Comment(
        #[rust_sitter::leaf(pattern = r"//[^\r\n]*", transform = |v| v.to_string())]
        pub String,
    );

    #[derive(Debug, Clone)]
    pub enum Operator {
        #[rust_sitter::leaf(text = "+")]
        Add,
        #[rust_sitter::leaf(text = "-")]
        Subtract,
        #[rust_sitter::leaf(text = "*")]
        Multiply,
        #[rust_sitter::leaf(text = "/")]
        Divide,
        #[rust_sitter::leaf(text = "==")]
        Equality,
        #[rust_sitter::leaf(text = "!=")]
        Inequality,
        #[rust_sitter::leaf(text = ">")]
        GreaterThan,
        #[rust_sitter::leaf(text = "<")]
        LessThan,
        #[rust_sitter::leaf(text = ">=")]
        GreaterThanEqual,
        #[rust_sitter::leaf(text = "<=")]
        LessThanEqual,
        #[rust_sitter::leaf(text = "&&")]
        And,
        #[rust_sitter::leaf(text = "||")]
        Or,
        #[rust_sitter::leaf(text = "!")]
        Not,
    }

    #[derive(Debug, Clone)]
    pub enum Boolean {
        #[rust_sitter::leaf(text = "true")]
        True,
        #[rust_sitter::leaf(text = "false")]
        False,
    }

    #[rust_sitter::extra]
    struct Whitespace {
        #[rust_sitter::leaf(pattern = r"\s")]
        _whitespace: (),
    }
}
