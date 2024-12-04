use crate::Problem;

pub struct Solution0001;

impl Problem for Solution0001 {
    fn id(&self) -> String {
        "0001".into()
    }

    fn run(&self) -> String {
        (1..1000)
            .filter(|i| i % 3 == 0 || i % 5 == 0)
            .sum::<u64>()
            .to_string()
    }
}
