# 25-u1-router-core

Adds the minimum klipper-router substrate required for auxiliary Klipper
instances on the Snapmaker U1 extended firmware branch.

Installed components:

- `/usr/local/sbin/klipper-routerd`
- `/etc/init.d/S98klipper-router-instances`
- `/etc/init.d/S99klipper-router`
- default router config in `extended/router/klipper_router.cfg`
- router macro include in `extended/klipper/15_router_api.cfg`
- firmware-config controls in `functions/25_settings_router.yaml`

Behavior:

- router startup is gated on `[router] enabled` in `extended2.cfg`
- instance startup is also gated globally by router enablement
- each instance may override `klippy_path`
- each instance may use `enabled_config` to bind startup to any
  `extended-config.py get <section> <key> <default>` boolean

This overlay is intentionally ACE-agnostic. It does not seed LED instances,
LED subscriptions, or reconnect migration hooks.
