# KARIM BUS SIMULATOR TANZANIA

**By KARIM GAMES STUDIO LIMITED**

This directory contains an early, procedural Godot 4 driving prototype on the `patch-1` branch. It is not a completed simulator or a production-ready Android release.

## Run

1. Install Godot 4.3 or newer (the project itself is tested only by opening/importing it in Godot; no engine executable was available in the authoring session).
2. Open `karim_bus_simulator/project.godot` in Godot and press **F6/F5** (or select `main.tscn`).
3. Press **START ROUTE**. Drive with **WASD** or arrow keys; **Space** applies the handbrake. Touch controls are included in the HUD.

## Current prototype features

- Runtime-built 3D highway, savanna ground, roadside trees/shops and labeled Dar es Salaam, Morogoro, Dodoma, Singida and Arusha stations.
- A procedural Scania-inspired coach silhouette with right-side cockpit, left-side passenger door, seats, wheels and a rigid-body heavy-vehicle force model.
- Keyboard and on-screen steering, throttle and brake; gear cycling, camera switching, headlights, indicators, weather grip toggle, passenger boarding, ticket income, fuel use, route HUD and day/night light-energy cycle.
- Godot project configured for landscape orientation and the GL Compatibility renderer for broad mobile support.

## Not yet implemented / not verified

This is a playable **vertical-slice prototype**, not the requested full game. The map is a short fictionalized/procedural test route, not a geographically accurate Tanzania map. The bus is procedural geometry, not an authored Scania model. There is no validated real-bus suspension/gearbox model, traffic AI, animated passenger boarding, real audio, menu/garage/career/save system, customizable controls, Android export preset, APK, rain particles or wet-road shader. On-screen GUI layout needs device testing. No Godot import, gameplay test, Android build or APK was run in this environment. Do not treat the force model or visuals as production-quality or physically validated.

## Next development steps

1. Import and run on Godot 4; fix any engine-version parsing or scene issues.
2. Tune vehicle forces and add wheel/suspension raycasts and a tested transmission model.
3. Replace procedural geometry with licensed optimized assets; build a surveyed route and streamed towns.
4. Add collision-tested traffic, pedestrian/passenger state machines, authored audio, save data and settings.
5. Test touch layout/performance on 4GB Android devices, configure Android SDK/export templates and produce a signed APK.
