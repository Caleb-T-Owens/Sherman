# Patc - The stupid patch tracker

Patc is a tool for managing project patches externally

Project status: Spec

## Usage

### `patc init`

Initializes an empty patc project in the current directory, creating the
following structure:

-   patc.json # A configuration which declares what repo should be checked
    out, and what branches to apply
-   .gitignore # A basic gitignore that ignores the `repo/` folder, and
    the `.patc-meta` file
-   branches/ # An empty folder where your branches will be stored.

`patc init` will only run if the `pwd` is empty.

### `patc.json` format

```json
{
    "repo": {
        "url": "repo url",
        "revision": "v6.5"
    },
    "applied-branches": ["my-tweaks", "gaps"]
}
```

-   repo.url: The URL of the repository that you want work on
-   repo.revision: The revision that the patches should be applied on top
    of. This _can_ be anything `git rev-parse` accepts, but I strongly
    recommend avoiding relative revisions (like `HEAD`). A branch name,
    tag, or commit sha are good choices.
-   applied-branches: The branches that should be applied on top of the
    specified revision. The branches will be applied in turn, starting at
    index 0.

    IE: IF you branch `x` which has commits `a` and `b`, and branch `y`
    which has commits `p` and `q`, the resulting commit graph will look like
    `base` -> `a` -> `b` -> `p` -> `q`

### Branch format

A branch is made by creating a folder inside `branches/`. A branch contains
many `.patch` files. The patches must be applyable by `git apply`.

Patches will be applied in alphabetical order.
If the patch starts with an order number IE: `0001-my-patch.patch`, the order
number will be trimmed before being formatted into the commit name format.

The commit name format is as follows: `patc(<branch-name>): <patch-name>`.

### `patc reapply`

This command performs several operations

## What problem does Patc solve?

With a program like `dwm` configuration is made by modifying the source code,
rather than by having some complex scripting language tie-in. This means that
the average `dwm` user will have a handful of patches made by other users
applied, as well as having some tweaks of their own.

Managing the application of these patches seems to be left as an exersize for
the reader. One approach could be to make a fork of `dwm` and have the patches
merged into your fork's `master` branch.

I keep all of my configuration in one monorepo, which makes it easy to sync
between machines and having sub-repos which specific checkouts would be a bit
a pain to manage (we all know how much everyone loves git submodules).

When I think about the data that I want to be responsible for, it's really only
the specific set of patches that I want applied. As such, the idea for a tool
that clones a git repository, and can apply and unapply specific patches.
