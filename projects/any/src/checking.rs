use std::collections::{HashMap, HashSet};

use anyhow::Result;

use crate::grammar::g;

const STRING_T: &str = "String";
const NUMBER_T: &str = "Number";
const BOOLEAN_T: &str = "Boolean";

#[derive(Debug, Clone, PartialEq)]
struct Signature {
    // Probably want to have some sort of "type identifier"
    from: Vec<String>,
    to: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct Function {
    name: String,
    sig: Signature,
    exps: Vec<g::Expression>,
}

impl Signature {
    fn empty() -> Self {
        Self {
            from: vec![],
            to: vec![],
        }
    }
}

#[derive(Debug, PartialEq)]
pub enum ProgramCheckResult {
    Valid,
    Invalid {
        type_errs: HashMap<String, ExpressionSignatureError>,
        duplicate_ids: Vec<String>,
        missing_main: bool,
    },
}

/// Checking has a couple of steps
///
/// - Ensures main fn exists with appropriate structure
/// - Collects signatures
/// - Checks the expressions in functions
#[allow(dead_code)]
pub fn check(program: &g::Program, std_lib: &[Function]) -> ProgramCheckResult {
    let prog = collect_functions(program);
    let fns = [&prog, std_lib].concat();
    let mut name_set = HashSet::new();
    let mut duplicate_names = vec![];
    let mut expression_errors = HashMap::new();
    for f in &prog {
        if name_set.contains(&f.name) {
            duplicate_names.push(f.name.clone());
            continue;
        }
        name_set.insert(f.name.clone());

        let res = expressions_to_signature(&f.sig.from, &f.exps, &fns);
        match res {
            Ok(res) => {
                if res != f.sig {
                    expression_errors.insert(
                        f.name.clone(),
                        ExpressionSignatureError::InconsistentStackState(
                            StackApplicationResult::MismatchedTypes {
                                expected: f.sig.from.clone(),
                                found: res.from,
                            },
                        ),
                    );
                }
            }
            Err(check_err) => {
                expression_errors.insert(f.name.clone(), check_err);
            }
        }
    }

    if duplicate_names.is_empty() && expression_errors.is_empty() && name_set.contains("main") {
        ProgramCheckResult::Valid
    } else {
        ProgramCheckResult::Invalid {
            type_errs: expression_errors,
            duplicate_ids: duplicate_names,
            missing_main: !name_set.contains("main"),
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum ExpressionSignatureError {
    MissingIdentifier,
    InconsistentBranches,
    IfWithoutElseUnbalanced,
    InconsistentStackState(StackApplicationResult),
}

fn expressions_to_signature(
    current_stack: &[String],
    exps: &[g::Expression],
    fns: &[Function],
) -> Result<Signature, ExpressionSignatureError> {
    let mut stack_state = current_stack.to_owned();

    for exp in exps {
        let exp_sig = expression_to_signature(&stack_state, exp, fns)?;
        let applicable = sig_applicable_to_stack(&stack_state, &exp_sig);
        match applicable {
            StackApplicationResult::Applicable => {
                stack_state.truncate(stack_state.len() - exp_sig.from.len());
                stack_state.append(&mut exp_sig.to.clone());
            }
            a => return Err(ExpressionSignatureError::InconsistentStackState(a)),
        }
    }

    Ok(Signature {
        from: current_stack.to_owned(),
        to: stack_state,
    })
}

fn expression_to_signature(
    current_stack: &[String],
    exp: &g::Expression,
    fns: &[Function],
) -> Result<Signature, ExpressionSignatureError> {
    match exp {
        g::Expression::Comment(_) => Ok(Signature::empty()),
        g::Expression::Literal(c) => Ok(Signature {
            from: vec![],
            to: vec![literal_to_type(&c.value)],
        }),
        g::Expression::Identifier(i) => fns
            .iter()
            .find_map(|f| {
                if f.name == i.value.0 {
                    Some(f.sig.clone())
                } else {
                    None
                }
            })
            .ok_or(ExpressionSignatureError::MissingIdentifier),
        g::Expression::Operator(o) => Ok(o.value.clone().into()),
        g::Expression::Conditional(c) => {
            let applicable = sig_applicable_to_stack(
                current_stack,
                &Signature {
                    from: vec![BOOLEAN_T.into()],
                    to: vec![],
                },
            );
            if applicable != StackApplicationResult::Applicable {
                return Err(ExpressionSignatureError::InconsistentStackState(applicable));
            }

            let c = &c.value;
            let without_bool = current_stack
                .iter()
                .take(current_stack.len() - 1)
                .cloned()
                .collect::<Vec<_>>();
            let t_sig = expressions_to_signature(
                &without_bool,
                &c.exps.iter().map(|e| e.value.clone()).collect::<Vec<_>>(),
                fns,
            )?;
            if let Some(e) = &c.conditional_else {
                let e = &e.value;
                let f_sig = expressions_to_signature(
                    &without_bool,
                    &e.exps.iter().map(|e| e.value.clone()).collect::<Vec<_>>(),
                    fns,
                )?;
                if t_sig == f_sig {
                    Ok(Signature {
                        from: current_stack.to_owned(),
                        to: t_sig.to,
                    })
                } else {
                    Err(ExpressionSignatureError::InconsistentBranches)
                }
            } else if t_sig.from == t_sig.to {
                Ok(Signature {
                    from: current_stack.to_owned(),
                    to: t_sig.to,
                })
            } else {
                Err(ExpressionSignatureError::IfWithoutElseUnbalanced)
            }
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum StackApplicationResult {
    Applicable,
    StackTooShort,
    MismatchedTypes {
        expected: Vec<String>,
        found: Vec<String>,
    },
}

fn sig_applicable_to_stack(stack: &[String], sig: &Signature) -> StackApplicationResult {
    if stack.len() < sig.from.len() {
        return StackApplicationResult::StackTooShort;
    }
    let tip = &stack[(stack.len() - sig.from.len())..];
    if tip == sig.from {
        StackApplicationResult::Applicable
    } else {
        StackApplicationResult::MismatchedTypes {
            expected: sig.from.to_owned(),
            found: tip.to_owned(),
        }
    }
}

/// Collect all the defined funciton signatures in the file
fn collect_functions(program: &g::Program) -> Vec<Function> {
    program
        .statements
        .iter()
        .filter_map(|s| match &s.value {
            g::Statement::Function(f) => Some(Function {
                name: f.name.value.0.clone(),
                sig: f.value.clone().into(),
                exps: f.expressions.clone().into_iter().map(|a| a.value).collect(),
            }),
            _ => None,
        })
        .collect()
}

fn literal_to_type(c: &g::Literal) -> String {
    match c {
        g::Literal::Number(_) => NUMBER_T.into(),
        g::Literal::String(_) => STRING_T.into(),
        g::Literal::Boolean(_) => BOOLEAN_T.into(),
    }
}

impl From<g::Operator> for Signature {
    fn from(value: g::Operator) -> Self {
        match value {
            g::Operator::Add
            | g::Operator::Subtract
            | g::Operator::Divide
            | g::Operator::Multiply => Signature {
                from: vec![NUMBER_T.into(), NUMBER_T.into()],
                to: vec![NUMBER_T.into()],
            },
            g::Operator::Equality
            | g::Operator::Inequality
            | g::Operator::GreaterThan
            | g::Operator::GreaterThanEqual
            | g::Operator::LessThan
            | g::Operator::LessThanEqual => Signature {
                from: vec![NUMBER_T.into(), NUMBER_T.into()],
                to: vec![BOOLEAN_T.into()],
            },
            g::Operator::And | g::Operator::Or => Signature {
                from: vec![BOOLEAN_T.into(), BOOLEAN_T.into()],
                to: vec![BOOLEAN_T.into()],
            },
            g::Operator::Not => Signature {
                from: vec![BOOLEAN_T.into()],
                to: vec![BOOLEAN_T.into()],
            },
        }
    }
}

impl From<g::Function> for Signature {
    fn from(value: g::Function) -> Self {
        value.signature.value.into()
    }
}

impl From<g::FunctionSignature> for Signature {
    fn from(value: g::FunctionSignature) -> Self {
        Self {
            from: value.from.iter().map(|v| v.value.0.clone()).collect(),
            to: value.to.iter().map(|v| v.value.0.clone()).collect(),
        }
    }
}

#[cfg(test)]
mod test {
    use std::collections::HashMap;

    use crate::{
        checking::{
            BOOLEAN_T, ExpressionSignatureError, Function, NUMBER_T, ProgramCheckResult, STRING_T,
            Signature, StackApplicationResult, check, sig_applicable_to_stack,
        },
        grammar::g,
    };

    fn std_lib() -> Vec<Function> {
        vec![
            Function {
                name: "dropn".into(),
                sig: Signature {
                    from: vec![NUMBER_T.into()],
                    to: vec![],
                },
                exps: vec![],
            },
            Function {
                name: "drops".into(),
                sig: Signature {
                    from: vec![STRING_T.into()],
                    to: vec![],
                },
                exps: vec![],
            },
            Function {
                name: "dropb".into(),
                sig: Signature {
                    from: vec![BOOLEAN_T.into()],
                    to: vec![],
                },
                exps: vec![],
            },
        ]
    }

    #[test]
    fn tip_matches() {
        let stack = ["String", "Number", "Boolean", "String"]
            .into_iter()
            .map(Into::into)
            .collect::<Vec<_>>();
        let sig = Signature {
            from: vec!["Boolean".into(), "String".into()],
            to: vec!["Number".into(), "String".into()],
        };
        assert_eq!(
            sig_applicable_to_stack(&stack, &sig),
            StackApplicationResult::Applicable
        );
    }

    #[test]
    fn tip_matches_eq_length() {
        let stack = ["Boolean", "String"]
            .into_iter()
            .map(Into::into)
            .collect::<Vec<_>>();
        let sig = Signature {
            from: vec!["Boolean".into(), "String".into()],
            to: vec!["Number".into(), "String".into()],
        };
        assert_eq!(
            sig_applicable_to_stack(&stack, &sig),
            StackApplicationResult::Applicable
        );
    }

    #[test]
    fn tip_matches_too_long() {
        let stack = ["String"].into_iter().map(Into::into).collect::<Vec<_>>();
        let sig = Signature {
            from: vec!["Boolean".into(), "String".into()],
            to: vec!["Number".into(), "String".into()],
        };
        assert_eq!(
            sig_applicable_to_stack(&stack, &sig),
            StackApplicationResult::StackTooShort
        );
    }

    #[test]
    fn tip_matches_mismatched_types() {
        let stack = vec![NUMBER_T.into(), STRING_T.into()];
        let sig = Signature {
            from: vec![BOOLEAN_T.into(), STRING_T.into()],
            to: vec![NUMBER_T.into(), STRING_T.into()],
        };
        assert_eq!(
            sig_applicable_to_stack(&stack, &sig),
            StackApplicationResult::MismatchedTypes {
                found: stack,
                expected: sig.from
            }
        );
    }

    #[test]
    fn constant_checking() {
        let prog = "
def main(->)
    42
    dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);

        let prog = "
def main(->)
    \"foobar baz\"
    drops
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);

        let prog = "
def main(->)
    \"foobar baz\"
    drops
    \"foobar baz\"
    drops
    \"foobar baz\"
    \"foobar baz\"
    drops
    drops
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);
    }

    #[test]
    fn function_calling_checking() {
        let prog = "
def add(Number, Number -> Number)
    dropn
end

def main(->)
    42 24 add
    dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);

        let prog = "
def add(String, Number -> Number)
    dropn
    drops
    42
end

def main(->)
    42 24 add
    dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(
            check(&prog, &std_lib()),
            ProgramCheckResult::Invalid {
                type_errs: HashMap::from([(
                    "main".into(),
                    ExpressionSignatureError::InconsistentStackState(
                        StackApplicationResult::MismatchedTypes {
                            expected: vec![STRING_T.into(), NUMBER_T.into()],
                            found: vec![NUMBER_T.into(), NUMBER_T.into()]
                        }
                    )
                )]),
                duplicate_ids: vec![],
                missing_main: false
            }
        );
    }

    #[test]
    fn if_expresson_checking() {
        let prog = "
def main(->)
    53 12
    false if
        42 dropn
    end
    + dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);

        let prog = "
def main(->)
    53 12
    false if
        42
    end
    + + dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(
            check(&prog, &std_lib()),
            ProgramCheckResult::Invalid {
                type_errs: HashMap::from([(
                    "main".into(),
                    ExpressionSignatureError::IfWithoutElseUnbalanced
                )]),
                duplicate_ids: vec![],
                missing_main: false
            }
        );

        let prog = "
def main(->)
    53 12
    false if
        42
    else
        24
    end
    + + dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);

        let prog = "
def main(->)
    53 12
    false if
        42 12
    else
        24
    end
    + + dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(
            check(&prog, &std_lib()),
            ProgramCheckResult::Invalid {
                type_errs: HashMap::from([(
                    "main".into(),
                    ExpressionSignatureError::InconsistentBranches
                )]),
                duplicate_ids: vec![],
                missing_main: false
            }
        );

        let prog = "
def main(->)
    53 12
    false if
        true if 13 else 41 end
    else
        false if 13 else 41 end
    end
    + + dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(check(&prog, &std_lib()), ProgramCheckResult::Valid);

        let prog = "
def main(->)
    53 12
    if
        42
    else
        24
    end
    + + dropn
end
";
        let prog = g::parse(prog).unwrap();
        assert_eq!(
            check(&prog, &std_lib()),
            ProgramCheckResult::Invalid {
                type_errs: HashMap::from([(
                    "main".into(),
                    ExpressionSignatureError::InconsistentStackState(
                        StackApplicationResult::MismatchedTypes {
                            expected: vec![BOOLEAN_T.into()],
                            found: vec![NUMBER_T.into()]
                        }
                    )
                )]),
                duplicate_ids: vec![],
                missing_main: false
            }
        );
    }
}
