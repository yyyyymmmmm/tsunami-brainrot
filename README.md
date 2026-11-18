# Tsunami Brainrot Bay

An entry for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01): a 3D
brainrot collector in the Steal-a-Brainrot genre, set on a tropical island bay.

Brainrot characters wander the grass field. Walk into one to grab it, carry it home to your base's
glowing bank pad, and it stands on a display pad paying you cash every second. Spend cash at the egg
machine for a random hatch across five rarities (Common, Rare, Epic, Legendary, Mythic), climb the
cast ladder from Patatino Fritto to Galassia Gelatina, and rebirth at the shrine for a permanent
income multiplier. Every couple of minutes a tsunami sweeps the bay: caught out in the open, you
lose the character you are carrying and wash up back at spawn. Banked characters are safe.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the binary place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`. The world itself is built at runtime by the
  server scripts, so the whole game lives in the Luau under `src/`:
  - `src/server/CharacterData.luau` - the twelve-character cast, the rarity ladder, tuning.
  - `src/server/WorldBuilder.luau` - island, water, palms, bases, egg machine, rebirth shrine.
  - `src/server/CharacterFactory.luau` - builds each creature from parts, with its name label.
  - `src/server/GameManager.luau` - spawning, wandering, grabbing, banking, income, eggs,
    rebirths and the tsunami; all game state lives here.
  - `src/server/init.server.luau` - wires the modules together and starts the game.
  - `src/client/Game.client.luau` - the HUD: cash, income, carried indicator, toasts, tsunami banner.
- `PLAY.json` names the published Roblox place; it is filled in when the game is published.

Run the hand-in locally, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
