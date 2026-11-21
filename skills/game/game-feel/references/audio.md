# Audio recipes and levels

Read `packages/audio/AGENTS.md` in the lab for the current API; this is how to use it.

## Mixer

- Buses: music, effects, interface, into master, into a safety compressor. Defaults: voice cap 24, bus levels music -6 dB, effects 0, interface -2, compressor -6 dB threshold. Keep the compressor idle: reduction beyond about 6 dB means the rows are too hot.
- `mixer.play(name, { gameTime })` returns `played` or `dropped` with a reason (`locked`, `interval`, `sound-cap`, `voice-cap`). `mixer.playLog` and `droppedLog` are what `check` reads.
- Events that matter duck the music: `duckDb` 3 to 6 and `duckMs` 200 to 1000, longer for rarer events.

## Rows

| Kind | Peak (`targetPeakDbfs`) | Notes |
| ---- | ----------------------- | ----- |
| Big rare event (explosion, level up, death) | -6 to -10 | priority 8 to 10, one or two voices, ducks music |
| Frequent impact (hit, kill) | -8 to -10 | cooldown 50 to 80 ms, 2 to 3 voices |
| Pickup, jump, dash, shoot | -14 to -16 | pitch variance 60 to 130 cents so repeats do not grate |
| Interface | -16 to -24 | one voice, quietest is hover |
| Ambient bed | about -30 | music bus |

A single event stays under -3 dBFS; the loudest event stays within about 12 dB of the median event. These are heuristics from the starter rows: tune by ear and by `check` numbers.

## Recipes

A recipe is layers of tones (sine, triangle, square, sawtooth; `fromHz` sliding to `toHz`) and filtered noise, whose gains sum to the nominal peak. Rising pitch for gain, falling for loss, noise for impact; a body layer (low sine) plus a short transient layer (high click or noise) makes a hit. Keep events short (under 400 ms) and distinct in pitch from neighbours. The same recipe, seed and pitch ratio render the same samples, so `renderRecipeSamples` and `measureSamples` check a sound in Node.

## Music

- `createSequencer(mixer, { now, pattern, seed, intensity })` plays a `MusicPattern` (bpm, steps per bar, layers) on the audio clock. Ship patterns: `ARENA_LOOP`, `CALM_AMBIENT`, `VICTORY_STING`; merge the pattern's `sounds` into the mixer table.
- Vertical layering: each layer has a `minIntensity`; set `setIntensity(0..1)` from game state (enemies, health, wave). A change fades in at the next bar, never mid-bar.
- Against repetition: two to four variants per layer, `chance` on filler notes, layers of unequal `lengthSteps` that realign only at their least common multiple.
- Keep the layer stack under -18 dBFS before the music bus. Chiptune 100 to 140 BPM, ambient 50 to 80.
- Stings (victory) play on the effects bus and duck the music.
- Under `pnpm check`'s virtual clock the audio clock barely moves: drive the sequencer's `now` and `tick()` from game time as the game template does, and stamp notes with game time (`gameTimeAt`).
- Scene target: short-term loudness about -18 LUFS (plus or minus 3 LU), sample peak at or below -1 dBFS, no DC offset, a loop wraps without a click. `check` measures all of these.
