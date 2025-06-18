use std::{
    ops::{Deref, DerefMut},
    path::PathBuf,
};

use anyhow::Result;

pub mod log;

#[derive(Clone)]
pub struct But {
    repo: gix::Repository,
}

impl But {
    pub fn open(path: impl Into<PathBuf>) -> Result<Self> {
        let repo = gix::open(path)?;
        Ok(Self { repo })
    }
}

impl Deref for But {
    type Target = gix::Repository;

    fn deref(&self) -> &Self::Target {
        &self.repo
    }
}

impl DerefMut for But {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.repo
    }
}
