# Shadow Card Game

A dark silhouette card battle game built in Godot 4. 3 battles, ~10 minutes, no assets required.

## Running the Project

1. Open Godot 4 (4.2+)
2. Import the project folder
3. Press F5 to run — starts immediately from the title screen

## Project Structure

```
shadow-card-game/
├── autoload/
│   └── GameState.gd      # Global state: player stats, deck, card/enemy data
├── scenes/
│   ├── Main.tscn/.gd     # Title screen
│   ├── combat/
│   │   ├── CombatScene.tscn/.gd  # Main battle scene (builds all UI in code)
│   └── ui/
│       ├── CardNode.tscn/.gd     # Card visual with hover/play animations
│       ├── EnemyNode.tscn/.gd    # Procedurally drawn silhouette enemy
│       ├── RewardScreen.tscn/.gd # Post-battle card selection
│       └── EndScreen.tscn/.gd    # Victory / defeat screen
```

## Core Systems

**GameState (autoload)** — Single source of truth. Holds all card/enemy definitions as inline dictionaries, player HP/deck/statuses, and helpers like `draw_cards()`, `take_damage()`, `apply_block()`.

**CombatScene** — Builds the entire battle UI programmatically in `_ready()`. Manages the turn loop: player plays cards → End Turn → enemy executes its pattern entry → repeat. Uses Tweens for all animations.

**EnemyNode** — Draws silhouette characters via `_draw()` (no art files). Three shapes: wisp, knight, monarch. Each pulses and floats procedurally.

**CardNode** — Draws cards via `_draw()` using StyleBoxFlat + font rendering. Hover lifts the card; click emits `card_clicked(index)`.

## How to Add Cards

In `autoload/GameState.gd`, add an entry to `CARDS`:

```gdscript
"my_card": {
    "id": "my_card", "name": "My Card", "cost": 1,
    "description": "Deal 9 damage.",
    "type": "attack",   # "attack" = red header, "skill" = blue
    "effects": [{"type": "damage", "value": 9}]
},
```

Effect types: `damage`, `damage_multi` (+ `times`), `block`, `heal`, `gain_energy`, `apply_status` (+ `target`, `status`, `amount`).

Add it to `get_reward_options()` pool so it can appear as a reward.

## How to Add Enemies

In `autoload/GameState.gd`, add an entry to `ENEMIES` (index 0 = battle 1, etc.):

```gdscript
{
    "name": "My Enemy",
    "max_hp": 60,
    "is_boss": false,
    "size_mult": 1.0,          # visual scale
    "eye_color": Color(1, 0, 0),
    "glow_color": Color(0.5, 0.1, 0.9),
    "shape": "wisp",           # "wisp" | "knight" | "monarch"
    "pattern": [
        {"type": "attack", "value": 8, "desc": "Attacks for 8"},
        {"type": "block",  "value": 6, "desc": "Braces"},
    ]
},
```

Pattern types: `attack`, `attack_buff` (+ `buff` strength), `attack_multi` (+ `times`), `block`, `apply_status` (+ `status`, `amount`).

## Status Effects

- **Vulnerable** (enemy): takes 50% more damage, decrements each enemy turn
- **Weak** (player or enemy): deals 25% less damage, decrements each turn
