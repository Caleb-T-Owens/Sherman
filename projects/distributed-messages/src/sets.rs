use std::collections::HashSet;
use std::hash::Hash;

#[derive(Clone, Debug)]
pub enum InvertibleSet<T> {
    Regular(HashSet<T>),
    Inverted(HashSet<T>),
}

impl<T> Default for InvertibleSet<T> {
    fn default() -> Self {
        Self::Regular(Default::default())
    }
}

impl<T> InvertibleSet<T> {
    #[expect(unused)]
    pub fn new(contents: impl Into<HashSet<T>>) -> Self {
        Self::Regular(contents.into())
    }

    #[expect(unused)]
    pub fn contents(&self) -> Option<impl Iterator<Item = &T>> {
        match self {
            Self::Regular(lhs) => Some(lhs.iter()),
            _ => None,
        }
    }
}

impl<T> InvertibleSet<T>
where
    T: Clone,
{
    pub fn complement(&self) -> Self {
        match self {
            Self::Regular(set) => Self::Inverted(set.clone()),
            Self::Inverted(set) => Self::Regular(set.clone()),
        }
    }
}

impl<T> InvertibleSet<T>
where
    T: Eq + Hash,
{
    pub fn insert(&mut self, item: T) {
        match self {
            Self::Regular(lhs) => lhs.insert(item),
            Self::Inverted(lhs) => lhs.remove(&item),
        };
    }

    pub fn remove(&mut self, item: T) {
        match self {
            Self::Regular(lhs) => lhs.remove(&item),
            Self::Inverted(lhs) => lhs.insert(item),
        };
    }
}

impl<T> InvertibleSet<T>
where
    T: Clone + Eq + Hash,
{
    pub fn union(&self, rhs: &Self) -> Self {
        match (self, rhs) {
            (Self::Regular(lhs), Self::Regular(rhs)) => {
                Self::Regular(lhs.union(rhs).cloned().collect())
            }
            (Self::Inverted(lhs), Self::Inverted(rhs)) => {
                Self::Inverted(lhs.intersection(rhs).cloned().collect())
            }
            (Self::Regular(lhs), Self::Inverted(rhs)) => {
                Self::Inverted(rhs.difference(lhs).cloned().collect())
            }
            (Self::Inverted(lhs), Self::Regular(rhs)) => {
                Self::Inverted(lhs.difference(rhs).cloned().collect())
            }
        }
    }

    pub fn intersection(&self, rhs: &Self) -> Self {
        match (self, rhs) {
            (Self::Regular(lhs), Self::Regular(rhs)) => {
                Self::Regular(lhs.intersection(rhs).cloned().collect())
            }
            (Self::Inverted(lhs), Self::Inverted(rhs)) => {
                Self::Inverted(lhs.union(rhs).cloned().collect())
            }
            (Self::Regular(lhs), Self::Inverted(rhs)) => {
                Self::Regular(lhs.difference(rhs).cloned().collect())
            }
            (Self::Inverted(lhs), Self::Regular(rhs)) => {
                Self::Regular(rhs.difference(lhs).cloned().collect())
            }
        }
    }
}
