# SDFB Project Handoff

## 1. Project Summary
`SDFB` is a Roblox game (Rojo workflow) built around short disaster rounds where players collect and rescue "brainrots" to grow a personal base economy.

Core loop:
1. Round starts with a random disaster.
2. Brainrots spawn in the disaster area.
3. Players carry one brainrot at a time and bring it to rescue zones.
4. Rescued brainrots are added to the player's base collection (if base has space).
5. Base brainrots generate passive cash over time.

## 2. Tech Stack and Workflow
- Engine: Roblox Studio
- Sync/build: Rojo
- Language: Luau
- Project mapping: `default.project.json`

Run flow:
1. `rojo serve`
2. Open place in Roblox Studio
3. Play test

Important Studio setting for persistence:
- `Game Settings -> Security -> Enable Studio Access to API Services` must be ON.

## 3. Current Feature Set

### Round and Disaster
- Continuous rounds with short intermission.
- Disaster selection uses weighted chance.
- Active disaster shown in UI.
- Implemented disasters:
  - Rising Lava
  - Meteor Shower
  - Tsunami
- Rising Lava is controlled through `Config.DisasterSettings.RisingLava` (start height, max height, speed multiplier), so you can easily tune how high/fast the lava rises without editing scripts.

### Brainrot Interaction
- Random rarity spawn (weighted).
- Each spawned brainrot has:
  - rarity
  - generated name
  - `incomePerSecond`
- Pickup uses proximity prompt with hold duration.
- Swap behavior: picking up a new brainrot drops current one and picks new one.
- Drop on death at death location.

### Rescue Rules
- Rescue zones on map.
- If base is full, rescue is blocked and player gets warning.
- Player can delete base brainrots mid-round to free capacity.

### Base System
- Players spawn in lobby until they claim an unclaimed base.
- Base claim via proximity prompt + visible claim marker.
- Claimed base becomes respawn location.
- Base displays owned brainrots as world objects.
- In-world delete prompt on base brainrots.
- Each brainrot spawns a neon collect pad in front; pads bank that brainrot's income over time only while the base is loaded, and stepping on the pad (owner only) pays out everything banked with a short cooldown.

### UI / Menus
- Top HUD: phase/time + active disaster.
- Buttons: Base Menu, Robux Shop, Rebirth, Settings.
- Single-active-menu behavior.
- Delete confirmation modal (used by base menu and in-world delete flow).
- Base full warning message.

### Economy and Progression
- Passive income was removed; players earn cash by walking across their brainrot collect pads.
- Banked income persists across sessions and only accrues while the base instance is active, so logging off freezes production until you return.
- Leaderstats track rescued count, round rescues, cash, and current income-per-second for bragging rights.
- Base capacity limit enforced.

### Persistence
- DataStore save/load for:
  - cash
  - owned brainrots (id, rarity, name, income)
  - id counter
- Save throttling and retry logic to reduce request pressure.

## 4. Code Architecture (Server)
- `src/server/Main.server.luau`
  - Boots all services.

- `RoundService`
  - Round state machine and round timing.
  - Writes round state into `ReplicatedStorage.RoundState`.

- `DisasterService`
  - Weighted disaster selection and lifecycle start/stop.

- `BrainrotService`
  - Spawns world brainrots + pickup prompts + labels.

- `CarryService`
  - Carry/swap/drop/rescue behavior and movement penalty.

- `RescueService`
  - Rescue zone logic and full-base blocking behavior.

- `PlayerDataService`
  - Runtime player data model.
  - Base capacity checks.
  - Economy values.
  - DataStore save/load.

- `BaseService`
  - Base claiming.
  - Base assignment/ownership.
  - Base display rendering.
  - Base spawn handling.

- `InventoryService`
  - Remote event wiring for delete and confirm flow.

- `EconomyService`
  - Guards against starting the economy loop twice (passive payouts now happen via base collect pads, not a background tick).

## 5. Code Architecture (Client)
- `src/client/Main.client.luau`
  - HUD + menu UI
  - Base menu list rendering from replicated player data
  - Delete confirmation modal
  - Warning/hint feedback
  - Single-active-panel state

## 6. Shared Config
Main tunables live in:
- `src/shared/Config/Config.luau`

Important values:
- Round timings
- Prompt hold/cooldown
- Base capacity
- Rarity spawn weights
- Rarity income values
- Label max distances
- Disaster weights
- Disaster-specific tunables (e.g., `Config.DisasterSettings.RisingLava.PlatformHeight`)
- Brainrot collect pad cooldown (`Config.BrainrotCollectCooldownSeconds`)

## 7. Replication Contracts
### ReplicatedStorage
- `RoundState`
  - `Phase`
  - `TimeLeft`
  - `DisasterName`
- `Remotes`
  - `DeleteBrainrot`
  - `BaseFullNotice`
  - `ShowDeleteConfirm`

### Player objects
- `leaderstats` values
- `RuntimeStats` (`CashPerSecond`)
- `BaseBrainrots` folder containing owned entries

## 8. Recreation Checklist
If rebuilding from scratch:
1. Set up Rojo and project mapping.
2. Build round loop first.
3. Add carry/rescue core before disasters.
4. Add base ownership and capacity rule.
5. Add economy and passive income.
6. Add UI panels and delete confirmation flow.
7. Add DataStore with conservative save cadence and retries.
8. Add disasters and tune weights last.

## 9. Known Operational Notes
- DataStore queue warnings can happen in Studio during frequent test restarts.
- Published server behavior is more representative than rapid Studio stop/start loops.
- Keep DataStore writes conservative; do not save every second.

## 10. Map Anchors Workflow
Designers can lay out bases/rescue pads directly in Studio without editing scripts:

- Create `Workspace.MapAnchors`.
- Under it, add:
  - `BasePlots`: place `Part` anchors where you want base pads. Orientation and position drive the generated pad. Optional attributes:
    - `PlotName` (string) to override auto naming.
    - `PadSizeX`, `PadSizeY`, `PadSizeZ` (numbers) to override the default footprint (defaults come from `Config.BasePlotSize`).
- `RescueZones`: place `Part` anchors for rescue pads. Optional attributes:
  - `ZoneName` (string) for display/debug naming.
  - `ZoneSizeX`, `ZoneSizeZ` (numbers) to resize the pad footprint.
- If you already built the final rescue geometry, just move the parts under `Workspace.RescueZones` and (optionally) set folder attribute `SkipAutoZones = true` to disable fallback pads entirely. The service automatically binds every part inside the folder and listens for new parts added later.
- On server start, `BaseService` clears `Workspace.PlayerBases` and spawns pads at every anchor; `RescueService` does the same for `Workspace.RescueZones`.
- Existing fallback positions are still used when no anchors exist.
- Brainrot spawn markers stay customizable through `Workspace.BrainrotSpawnMarkers_Base` (add/remove parts freely; the service no longer seeds fallback markers, so place every spawn point manually).
- Lobby spawn: place your own `LobbySpawn` part (any `BasePart`) in Workspace. BaseService reads its position +3 studs up for players without a base; if the part is missing it falls back to `(0, 3, 0)`.
 - Intermission gates: drop any bridge-blocking parts under `Workspace.IntermissionGates`. The server toggles their collisions automatically each phase; they're solid during intermission and open when the round starts. Parts tagged this way also repel players who haven't claimed a base (they're teleported back to lobby) and meteors ignore them to prevent midair explosions.
- Meteor spawn zones: to restrict Meteor Shower impacts to the disaster island, place flat parts in `Workspace.MeteorSpawnZones` **or** inside each disaster model’s `MeteorSpawnZones` folder. Meteors choose a random X/Z inside those parts and spawn at either the part’s `MeteorSpawnHeight` attribute or ~120 studs up.

## 11. Maintenance Notes (March 1, 2026)
- PlayerDataService now waits on the correct `Enum.DataStoreRequestType.SetIncrementAsync` budget before saving (this is the bucket Roblox charges for `SetAsync`), fixing a bug where we’d falsely assume we had write budget and risk throttling.
- Removed the unused `pending` counters inside PlayerDataService; round cleanup now simply resets the `RoundRescued` leaderstat.
- Deleted the dead `PlayerService` script (leaderstats are fully handled inside PlayerDataService) to reduce confusion.
- Removed the unused `createSpawnMarker` helper from MapLoaderService—brainrot spawn parts should always be authored directly in Studio under `Workspace.BrainrotSpawnMarkers_Base` or each disaster’s folder.
- EconomyService documentation now matches reality (no hidden passive tick; only the collect pads matter). 
