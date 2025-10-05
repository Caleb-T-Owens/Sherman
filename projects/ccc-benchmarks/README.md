# Git Blame CCC Benchmarks

`git blame -C -C -C` is a personal favourite command of mine, which usually
gives far more useful blame results compared to a regular `git blame` since it
does a better job of tracking the origional author of code moved around both
within a file and even code copied between files.

EG: If Geoff writes a file:

```rs
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
```

And then Bob re-orders the functions to:

```rs
use crate::Problem;

pub struct Solution0001;

impl Problem for Solution0001 {
    fn run(&self) -> String {
        (1..1000)
            .filter(|i| i % 3 == 0 || i % 5 == 0)
            .sum::<u64>()
            .to_string()
    }

    fn id(&self) -> String {
        "0001".into()
    }
}
```

Regular `git blame` would credit Bob as the author of the `id` and `run`
functions. Using the `-C` argument, it will instead look for code movement and
determine that Geoff was the actual author of the functions. Adding `-C` two
times and even a third increases the scope of the search for code movement.

I daily drive `-C -C -C` in my GitLens config:

```json
{
    "gitlens.advanced.blame.customArguments": ["-C", "-C", "-C"]
}
```

And asked if this could be upstreamed as a default or even being just a setting.

It was brought to my attention that on certain files, the performance gets way
out of hand in certain types of files. This supprised me since my anecdotal
evidence said otherwise.

As such, I decided to do some benchmarking.

To use this benchmark tool, clone a repo into the `example-repo` folder. EG:
`git clone git@github.com:gitbutlerapp/gitbutler.git example-repo`.

And run `cargo run generate-report` to generate the `output.jsonl`. You can then
run `cargo run basic-stats` for some adverages. You can also run `cargo run
to-csv` which will generate a CSV that you can import into your favourite
spreadsheet software.

On the GitButler repo, the results are as follows:

```
mean normal: 35.48317893710385
mean c: 51.19307654802535
mean cc: 223.04485616772305
mean ccc: 657.6977084349098
median normal: 33
median c: 43
median cc: 122
median ccc: 275
75% normal: 45
75% c: 62
75% cc: 230
75% ccc: 691
95% normal: 72
95% c: 107
95% cc: 683
95% ccc: 2407
```

With these results, my anecdotal evidence makes more sense. For my GitLens
usage, even waiting 2.5 seconds is acceptable. That said, in that last 5%, the
performance really balloons out of control.

Chart of CCC performance:
![](/projects/ccc-benchmarks/ccc-duration.png)

I was hoping that there would be a coorelation between file line length and time taken compute. If there was we could use it as a basic heuristic, but unfortunately that is not the case:

Chart of CCC performance compared to line lenth. The horizontal axis is lines, and vertical time taken:
![](/projects/ccc-benchmarks/time-taken-against-line-length.png)
