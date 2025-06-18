use std::{collections::HashSet, sync::Arc};

use crate::But;

use anyhow::Result;

#[derive(Debug, PartialEq, Clone)]
pub enum Entry {
    Commit {
        id: gix::ObjectId,
        from: Vec<usize>,
    },
    Wire {
        /// The object that this wire will eventually lead to.
        id: gix::ObjectId,
        /// The entry index that this wire came from.
        from: Vec<usize>,
    },
}

#[derive(Debug, PartialEq, Clone)]
pub struct Line {
    entries: Vec<Entry>,
}

impl ToString for Line {
    fn to_string(&self) -> String {
        let mut out = String::new();
        for entry in &self.entries {
            match entry {
                Entry::Commit { id, .. } => {
                    out.push_str(&format!(
                        " {} ",
                        id.to_string().chars().take(3).collect::<String>()
                    ));
                }
                Entry::Wire { .. } => out.push_str("  *  "),
            }
        }
        out
    }
}

#[derive(Clone)]
pub struct Log {
    first: Option<Line>,
    current: Arc<Result<Line>>,
    repo: gix::Repository,
}

impl Iterator for Log {
    type Item = Result<Line>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(first) = self.first.take() {
            self.current = Arc::new(Ok(first.clone()));
            return Some(Ok(first));
        }

        let Ok(current) = &*self.current else {
            return None;
        };
        let next = next_line(&self.repo, current).transpose();

        if let Some(next) = next {
            if let Ok(next) = next {
                self.current = Arc::new(Ok(next.clone()));
                Some(Ok(next))
            } else {
                self.current = Arc::new(next);
                None
            }
        } else {
            None
        }
    }
}

impl But {
    pub fn log(&self, start: gix::ObjectId) -> Log {
        let initial = Line {
            entries: vec![Entry::Commit {
                id: start,
                from: vec![],
            }],
        };

        Log {
            first: Some(initial.clone()),
            current: Arc::new(Ok(initial)),
            repo: self.repo.clone(),
        }
    }
}

fn test_inspect(lines: &[Line]) -> String {
    let mut out = String::new();
    for line in lines {
        for entry in &line.entries {
            match entry {
                Entry::Commit { id, .. } => {
                    out.push_str(&format!(
                        " {} ",
                        id.to_string().chars().take(3).collect::<String>()
                    ));
                }
                Entry::Wire { .. } => out.push_str("  *  "),
            }
        }
        out.push('\n');
    }
    out
}

fn next_line(repo: &gix::Repository, line: &Line) -> Result<Option<Line>> {
    let mut next_commits = vec![];

    for (i, entry) in line.entries.iter().enumerate() {
        match entry {
            Entry::Commit { id, .. } => {
                let commit = repo.find_commit(*id)?;
                let parent_ids = commit.parent_ids();

                for id in parent_ids {
                    let commit = id.object()?.into_commit();
                    next_commits.push(commit);
                }
            }
            Entry::Wire { id, .. } => {
                let commit = repo.find_commit(*id)?;
                next_commits.insert(i, commit);
            }
        }
    }

    let mut already_there = HashSet::new();

    next_commits.retain(|c| {
        if already_there.contains(&c.id) {
            false
        } else {
            already_there.insert(c.id);
            true
        }
    });

    let oldest = next_commits
        .iter()
        .enumerate()
        .filter_map(|(i, c)| Some((i, c.committer().ok()?.seconds())))
        .max_by_key(|(_, t)| *t);

    let Some((i, _)) = oldest else {
        return Ok(None);
    };

    let mut next_line = Line { entries: vec![] };

    for (ic, commit) in next_commits.into_iter().enumerate() {
        let from = line
            .entries
            .iter()
            .enumerate()
            .filter_map(|(i, e)| match e {
                Entry::Commit { id, .. } => {
                    let child = repo.find_commit(*id).ok()?;
                    let child_parents = child.parent_ids().collect::<Vec<_>>();
                    if child_parents.contains(&commit.id()) {
                        Some(i)
                    } else {
                        None
                    }
                }
                Entry::Wire { id, .. } => {
                    if *id == commit.id() {
                        Some(i)
                    } else {
                        None
                    }
                }
            })
            .collect::<Vec<_>>();

        if ic == i {
            next_line.entries.push(Entry::Commit {
                id: commit.id().detach(),
                from,
            });
        } else {
            next_line.entries.push(Entry::Wire {
                id: commit.id().detach(),
                from,
            });
        }
    }

    Ok(Some(next_line))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn write_commit<'a>(
        repo: &'a gix::Repository,
        time: i64,
        parents: &[gix::ObjectId],
    ) -> Result<gix::Id<'a>> {
        let signature = gix::actor::Signature {
            name: "A".into(),
            email: "A@example.com".into(),
            time: gix::date::Time::new(time, 0),
        };
        let commit = gix::objs::Commit {
            tree: gix::ObjectId::empty_tree(gix::hash::Kind::Sha1),
            parents: parents.to_vec().into(),
            author: signature.clone(),
            committer: signature,
            encoding: None,
            message: "A".into(),
            extra_headers: vec![],
        };
        let commit = repo.write_object(commit)?;
        Ok(commit)
    }

    mod log {
        use super::*;

        #[test]
        fn test_simple() -> Result<()> {
            let dir = tempdir::TempDir::new("foo")?;
            gix::init(dir.path())?;
            let but = But::open(dir.path())?;

            let a = write_commit(&but, 0, &[])?;
            let b = write_commit(&but, 1, &[a.detach()])?;
            let c = write_commit(&but, 2, &[b.detach()])?;

            let lines = but.log(c.detach()).collect::<Result<Vec<_>>>()?;

            assert_eq!(
                test_inspect(&lines),
                " f4a 
 2b6 
 f1c 
"
            );

            Ok(())
        }

        #[test]
        fn test_single_fork() -> Result<()> {
            let dir = tempdir::TempDir::new("foo")?;
            gix::init(dir.path())?;
            let but = But::open(dir.path())?;

            let a = write_commit(&but, 0, &[])?;
            let b = write_commit(&but, 1, &[a.detach()])?;
            let c = write_commit(&but, 2, &[a.detach()])?;
            let d = write_commit(&but, 3, &[c.detach(), b.detach()])?;

            let lines = but.log(d.detach()).collect::<Result<Vec<_>>>()?;

            assert_eq!(
                test_inspect(&lines),
                " d8f 
 f0a   *  
  *   2b6 
 f1c 
"
            );

            Ok(())
        }
    }

    mod next_line {
        use super::*;

        #[test]
        fn test_simple() -> Result<()> {
            let dir = tempdir::TempDir::new("foo")?;
            gix::init(dir.path())?;
            let but = But::open(dir.path())?;

            let a = write_commit(&but, 0, &[])?;
            let b = write_commit(&but, 1, &[a.detach()])?;
            let c = write_commit(&but, 2, &[b.detach()])?;

            let line = Line {
                entries: vec![Entry::Commit {
                    id: c.detach(),
                    from: vec![],
                }],
            };

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![Entry::Commit {
                        id: b.detach(),
                        from: vec![0],
                    }],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![Entry::Commit {
                        id: a.detach(),
                        from: vec![0],
                    }],
                }
            );

            let line = next_line(&but, &line)?;
            assert_eq!(line, None);

            Ok(())
        }

        #[test]
        fn test_single_fork() -> Result<()> {
            let dir = tempdir::TempDir::new("foo")?;
            gix::init(dir.path())?;
            let but = But::open(dir.path())?;

            let a = write_commit(&but, 0, &[])?;
            let b = write_commit(&but, 1, &[a.detach()])?;
            let c = write_commit(&but, 2, &[a.detach()])?;
            let d = write_commit(&but, 3, &[c.detach(), b.detach()])?;

            let line = Line {
                entries: vec![Entry::Commit {
                    id: d.detach(),
                    from: vec![],
                }],
            };

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: b.detach(),
                            from: vec![0],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Wire {
                            id: a.detach(),
                            from: vec![0],
                        },
                        Entry::Commit {
                            id: b.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![Entry::Commit {
                        id: a.detach(),
                        from: vec![0, 1],
                    }],
                }
            );

            let line = next_line(&but, &line)?;
            assert_eq!(line, None);

            Ok(())
        }

        #[test]
        fn test_fork_with_multiple_intermediates() -> Result<()> {
            let dir = tempdir::TempDir::new("foo")?;
            gix::init(dir.path())?;
            let but = But::open(dir.path())?;

            let a = write_commit(&but, 0, &[])?;
            let b = write_commit(&but, 1, &[a.detach()])?;
            let c = write_commit(&but, 2, &[a.detach()])?;
            let c2 = write_commit(&but, 3, &[c.detach()])?;
            let c3 = write_commit(&but, 4, &[c2.detach()])?;
            let d = write_commit(&but, 5, &[c3.detach(), b.detach()])?;

            let line = Line {
                entries: vec![Entry::Commit {
                    id: d.detach(),
                    from: vec![],
                }],
            };

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c3.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: b.detach(),
                            from: vec![0],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c2.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: b.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: b.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Wire {
                            id: a.detach(),
                            from: vec![0],
                        },
                        Entry::Commit {
                            id: b.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![Entry::Commit {
                        id: a.detach(),
                        from: vec![0, 1],
                    }],
                }
            );

            let line = next_line(&but, &line)?;
            assert_eq!(line, None);

            Ok(())
        }

        #[test]
        fn test_fork_with_multiple_intermediates_2() -> Result<()> {
            let dir = tempdir::TempDir::new("foo")?;
            gix::init(dir.path())?;
            let but = But::open(dir.path())?;

            let a = write_commit(&but, 0, &[])?;
            let b = write_commit(&but, 4, &[a.detach()])?;
            let c = write_commit(&but, 1, &[a.detach()])?;
            let c2 = write_commit(&but, 2, &[c.detach()])?;
            let c3 = write_commit(&but, 3, &[c2.detach()])?;
            let d = write_commit(&but, 5, &[c3.detach(), b.detach()])?;

            let line = Line {
                entries: vec![Entry::Commit {
                    id: d.detach(),
                    from: vec![],
                }],
            };

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Wire {
                            id: c3.detach(),
                            from: vec![0],
                        },
                        Entry::Commit {
                            id: b.detach(),
                            from: vec![0],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c3.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: a.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c2.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: a.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![
                        Entry::Commit {
                            id: c.detach(),
                            from: vec![0],
                        },
                        Entry::Wire {
                            id: a.detach(),
                            from: vec![1],
                        },
                    ],
                }
            );

            let line = next_line(&but, &line)?.unwrap();
            assert_eq!(
                line,
                Line {
                    entries: vec![Entry::Commit {
                        id: a.detach(),
                        from: vec![0, 1],
                    }],
                }
            );

            let line = next_line(&but, &line)?;
            assert_eq!(line, None);

            Ok(())
        }
    }
}
