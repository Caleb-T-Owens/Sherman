# Project Cloner 2

A little helper for incoorperating other git repositories into your monorepos without the need for submodules.

## Usage

Clones git repositories specified in a `cloned.json`

Example cloned.json:

```json
{
    "libgit2": {
        "url": "git@github.com:libgit2/libgit2.git",
        "profiles": ["work", "home"]
    }
}
```

The object key (IE: "libgit2") specifies the folder name that the repository should be cloned into.
The url property specifies where we can find the git repository.
The profiles property specifies which profiles the repository should be cloned for.

Environment variables:

-   CLONER_PROFILE: (required) Clones projects which specify a matching profile
-   CLONER_TARGET_DIRECTORY: (optional) Specify the directory where the `cloned.json` is, and where the projects should be cloned. Defaults to `pwd`.
