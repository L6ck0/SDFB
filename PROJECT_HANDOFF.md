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
  - Storm Winds

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

### UI / Menus
- Top HUD: phase/time + active disaster.
- Buttons: Base Menu, Robux Shop, Rebirth, Settings.
- Single-active-menu behavior.
- Delete confirmation modal (used by base menu and in-world delete flow).
- Base full warning message.

### Economy and Progression
- Brainrots in base generate passive cash.
- Leaderstats include rescued and cash-related values.
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
  - Periodic passive cash payout.

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

