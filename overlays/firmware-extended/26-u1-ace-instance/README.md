# 26-u1-ace-instance

Adds the ACE-specific auxiliary Klipper instance on top of
`25-u1-router-core`.

Installed components:

- `/home/lava/klipper-vanilla`
- `extended/klipper/16_router_ace_bridge.cfg`
- `extended/router/instances/ace/enabled_config`
- `extended/router/instances/ace/klippy_path`
- `extended/router/instances/ace/printer.cfg`
- `extended/router/instances/ace/klipper/10_ace_instance.cfg`
- `extended/router/instances/ace/klipper/20_ace_events.cfg`
- `functions/26_settings_ace.yaml`

Enable flow:

- set `[ace] enabled` to `true` in `extended2.cfg`
- `26_settings_ace.yaml` also ensures `[router] enabled` is `true`
- restart `S98klipper-router-instances`, `S99klipper-router`, and `S60klipper`

Manual bridge entry points on the main Klipper instance:

- `ACE_BRIDGE_RETRACT`
- `ACE_BRIDGE_FEED`
- `ACE_BRIDGE_DRY_START`
- `ACE_BRIDGE_DRY_STOP`
- `ACE_BRIDGE_LOAD_LANE`
- `ACE_BRIDGE_UNLOAD_LANE`
- `ACE_BRIDGE_LOAD_TOOL`
- `ACE_BRIDGE_UNLOAD_TOOL`

Calibration notes:

- `parkposition_to_toolhead_length`
- `parkposition_to_rdm_length`
- `total_max_feeding_length`
- `toolchange_load_length`

These are seeded as conservative TODO defaults and must be measured on
hardware before production use.

This first cut does not auto-hook proprietary Snapmaker toolchange macros.
The bridge is delivered as explicit macros until the on-device macro flow is
verified separately.
