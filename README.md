# Snowman

My Nix configuration for multiple machines.

## Government-mandated table

| Hostname  | OS    | Description               |
| --------- | ----- | ------------------------- |
| `acheron` | NixOS | KDE Plasma, entertainment |
| `tigris`  | NixOS | Has nothing               |
| `nile`    | macOS | MacBook                   |

## Layout

```
flake.nix                         The file of the hour
lib/                              Custom options and a helper function
hosts/<host>/                     Per-host settings and hardware configuration
modules/{common,linux,darwin}/    Respectively: shared, NixOS, nix-darwin
```
