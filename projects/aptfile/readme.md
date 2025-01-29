# Aptfile

Brewfiles but for `apt`!

## Usage

Aptfile is currently very basic, and is concerned with managing
all of your globally installed packages.

Brewfiles have special functionality for temporarily installing a smaller
subset of packages in for specific projects, but I'm not particularly concerned
with this usecase yet.

### `aptfile init`

Create a new `Aptfile` that contains all of the packages currently marked as
manually installed.

### `aptfile sync`

WARNING: You must be encredibly careful when editing your Aptfile.
Accidentally deleting the wrong entries could cause irreprible damage to your
system.

Compares the the list of manually installed packages against the packages in
the Aptfile.

First, any packages that are not already installed get installed by apt.

Second, looks through any packages missing from the Aptfile and checks to see
if anything depends on them.
If a package is missing from the Aptfile and isn't a dependency, it will be
purged.
If the package is missing from the Aptfile and is a dependency of another
package, it gets marked as automatically installed.

## Aptfile Format

`Aptfile`

```
entry
other-entry
# comment
```

## Notes

Reverse dependencies:
`apt-cache rdeps --installed <package-name>`
Returns:

```
<package-name>
Reverse Depends:
  foo
  bar
```

Manually installed packages:
`apt-mark showmanual`
Returns:

```
foo
bar
```
