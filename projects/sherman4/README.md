# Sherman v4 - The "Aaahh, shell is a monster, lets write it in TS" version

## Example usage

codium.sher.json

```json
{
  "name": "brew--codium",
  "layer": "brew",
  "commands": {
    "upsert": "echo \"cask \\\"codium\\\"\""
  },
  "dependencies": ["brew"]
}
```

sherman.json

```json
{
  "platforms": {
    "macos": {
      "entries": [
        "./entries/macos/**/sher.json",
        "./entries/macos/**/*.sher.json"
      ],
      "profiles": {
        "home": {
          "requires": "sherman-home.json",
          "commands": ["upsert"]
        },
        "work": {
          "requires": "sherman-work.json",
          "commands": ["upsert"]
        }
      }
    },
    "linux": {
      "entries": [
        "./entries/linux/**/sher.json",
        "./entries/linux/**/*.sher.json"
      ],
      "profiles": {
        "electron": {
          "requires": "sherman-electron.json",
          "commands": ["upsert"]
        }
      }
    }
  },
  "layers": {
    // Contains the command for installing brew itself
    "pre-brew": {},
    "brew": {
      "hooks": {
        // a script that gets executed after the upsert signal has been called
        // on all the brew dependencies.
        // It gets passed all the STDOUTs of the upsert commands as a JSON
        // array of strings.
        "upsert--after-all": "./brewfile-install.sh"
      }
    },
    "general-deps": {
      "hooks": {
        // A command that gets called on all the entries in the "general-deps"
        // layer that are **not** depended on.
        "upsert--cleanup-command": "uninstall"
      },
      "dependencies": ["pre-brew"]
    },
    "services": {
      "dependencies": ["brew", "general-deps"]
    }
  }
}
```

sherman-electron.json (dependencies for electron)

```json
{
  "dependencies": {
    "maybe": {},
    "microblog_api": {},
    "penpot": {},
    "website3": {}
  }
}
```

## Traversing a directed graph

I need to build some objects which note the required dependencies for entry
