# SamplePlugin

A minimal Unreal Engine 5.6+ editor plugin that adds a "Say Hello" button to the level editor toolbar.

Built as a **template** for new plugins — copy this folder and rename to start a new plugin quickly.

## What it does

When loaded, adds a button to the play-toolbar. Clicking it shows a message dialog. That's it.

The point is to demonstrate the minimal skeleton needed for:
- A `.uplugin` descriptor
- An editor module with `StartupModule` / `ShutdownModule`
- `TCommands<>` for declaring UI commands
- `UToolMenus` for adding toolbar buttons

## Install

### As a project plugin (typical)

```
YourProject/
└── Plugins/
    └── SamplePlugin/      ← drop folder here
```

Right-click your `.uproject` → **Generate Visual Studio project files** → build in VS.

### As a git submodule

```powershell
cd YourProject
git submodule add https://github.com/actimov2/SamplePlugin.git Plugins/SamplePlugin
```

## Engine version

UE 5.6+ (uses `EngineIncludeOrderVersion.Latest` and `BuildSettingsVersion.V5`).

## License

MIT — see LICENSE file.
