# Coin Dash

**Mode:** game
**Promise:** Grab coins before the clock runs out, in thirty seconds of pure momentum.

## Pillars
1. Momentum: movement always feels fast.
2. Greed: a risky coin always beats a safe one.

## Core loop
Move, collect coins, finish in 30 seconds, score, go again.

## Controls
Arrow keys or WASD.

## Not this
- No menus beyond title and game over.
- No health bars.
- No enemies.
- No upgrade shop.
- No dark fog look.

## Done condition
`pnpm check coin-dash` is green and a 30 second demo shows a full round.

## Cut list
1. Particle trails
2. Combo counter

## Features
- Coins spawn and score: the demo run ends in game-over with a score above zero.

## Demo mode
The bot grabs the nearest coin.

## Look direction
Warm sand ground, bright gold coins, teal sky.

## Next directions
1. Make the coins pop with a sound and a flash on pickup.
2. Add a title screen line that shows the controls.
3. Tighten the timer display so it reads from across the room.
