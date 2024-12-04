// use std::collections::HashMap;

use crate::Problem;

pub struct Solution0003;

impl Problem for Solution0003 {
    fn id(&self) -> String {
        "0003".to_string()
    }

    fn run(&self) -> String {
        let prime_factors = find_prime_factors(600851475143);
        // let prime_factors = find_prime_factors(13195);
        // dbg!(&prime_factors);
        prime_factors.iter().max().unwrap().to_string()
    }
}

fn find_prime_factors(mut target: u64) -> Vec<u64> {
    let mut output = vec![];
    let mut number = 1;
    // let mut result_cache = HashMap::new();

    loop {
        number += 1;
        // dbg!(number, target);
        if number > target {
            break;
        }

        // if !is_prime(&mut result_cache, number) {
        //     continue;
        // }

        if target % number == 0 {
            target /= number;
            output.push(number);
        }
    }

    output
}

/*
fn is_prime(result_cache: &mut HashMap<u64, bool>, target: u64) -> bool {
    if target == 2 {
        return true;
    }

    match result_cache.get(&target) {
        Some(result) => *result,
        None => {
            let mut target_is_prime = true;
            for number in 2..target {
                if !is_prime(result_cache, number) {
                    continue;
                }

                if target % number == 0 {
                    target_is_prime = false;
                    break;
                }
            }
            result_cache.insert(target, target_is_prime);
            target_is_prime
        }
    }
}
*/
