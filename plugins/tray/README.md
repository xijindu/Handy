# tray

System tray integration for Handy on macOS and Windows.

## API

The plugin owns call ordering, idempotency, call serialization and unchanged-payload suppression.
Callers declare the desired tray state; they never sequence platform calls themselves.

```dart
await Tray.instance.show(
  TraySpec(
    icon: TrayIcon.asset('assets/images/tray/macos/status_1.png', isTemplate: true),
    toolTip: 'Handy',
    menu: [
      TrayMenuAction(label: 'Show', onSelected: showWindow),
      const TrayMenuSeparator(),
      TrayMenuCheckbox(label: 'TUN', checked: true, onSelected: toggleTun),
      TrayMenuSubmenu(label: 'Proxy', items: proxyItems),
    ],
  ),
);

await Tray.instance.setTitle('↑ 1.2 MB/s');
await Tray.instance.hide();
```

- `show` creates the tray on first call and reconciles it afterwards. Re-sending a structurally
  identical `TraySpec` performs no platform call, so callbacks may be rebuilt freely.
- `setTitle` is the incremental path for high-frequency text. It is a no-op where
  `capabilities.title` is false, and while no tray is visible.
- `hide` is idempotent and returns native state to "`show` was never called", so a later `show`
  rebuilds the tray from scratch.
- `openMenu` is a no-op where `capabilities.menuControl` is false.

`TrayIcon.asset` names a bundled PNG and follows Flutter's resolution-aware layout: every
`2.0x/`, `3.0x/`, `4.0x/` sibling that exists is loaded too. macOS receives them all as
representations of one `size`-point image; Windows loads the path as-is, so point it at a
multi-size `.ico` instead.

Menu item ids are assigned by pre-order position, so an unchanged menu serializes identically across
rebuilds and click dispatch stays stable while a menu is open.

Actions, checkboxes and submenus take an optional `detail`, secondary text shown after the label, such as
a shortcut or a measured latency:

| macOS | Windows |
| --- | --- |
| right-aligned column in the color of a native key equivalent | the menu's accelerator column |

## Events

`Tray.instance.events` is a broadcast stream of `TrayIconActivated`, `TrayMenuRequested` and
`TrayMenuItemSelected`. Per-item `onSelected` callbacks fire before the corresponding stream event.
On Windows a left click is `TrayIconActivated` and a right click `TrayMenuRequested`; macOS opens the
menu from either button, as status items do there, so it only sends `TrayMenuRequested`.

## Capabilities

`Tray.instance.capabilities` reports what the current platform can do, so callers branch on ability
rather than on `Platform.isX`.

| | macOS | Windows |
| --- | --- | --- |
| `title` | yes | no |
| `toolTip` | yes | yes |
| `iconEvents` | yes | yes |
| `menuControl` | yes | yes |
