use crate::Problem;

pub struct Solution0002;

impl Problem for Solution0002 {
    fn id(&self) -> String {
        "0002".into()
    }

    fn run(&self) -> String {
        let mut acc: u128 = 2;
        let mut a: u64 = 1;
        let mut b: u64 = 2;

        loop {
            let c = a + b;
            a = b;
            b = c;

            if c > 4000000 {
                break;
            }

            if c % 2 == 0 {
                acc += c as u128;
            };
        }

        acc.to_string()
    }
}
