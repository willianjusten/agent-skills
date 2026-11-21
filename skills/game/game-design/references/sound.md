# Sound

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [sound-deep.md](sound-deep.md). Lab wiring (mixer, recipes, sequencer) stays in game-feel.

1. **Music is a composition with sections.** A motif or harmonic spine, named sections (intro, A, B, breakdown), and pitch that moves. Why: adaptive systems switch between sections. Check: list the sections; hum the motif back after a minute. [1][4][5][house]

2. **Nothing repeats exactly for 30 to 60 seconds.** Use several sections, 2 to 4 variants per layer, chance-gated filler notes, and layers of unequal length. Break when: the repetition is the point and short. Check: compute the length until all layers realign. [1][3][house]

3. **Pick the adaptive method.** Vertical layers for escalation within a phrase, horizontal resequencing for places and distinct states. Switch at bar or phrase marks; compose layers so any combination works. A reward melody gets its own layer in every section's key. Break when: a sudden stop is the effect. Check: force every state change and listen for seams. [1][2][3][house]

4. **Layers carry dynamics; quiet is planned.** Calm play gets one or two sparse layers, later waves add rhythm and the motif, a boss adds its own, a breakdown drops back. Check: plot active layers over a session; it needs valleys. [2][1][8][4][5][house]

5. **One distinct sound per event; sound covers the screen.** Each event the player cares about differs in pitch or character from its neighbours. Off-screen threats cue before they land; a cue plays only while relevant. Break when: events merge into a texture; group them. Check: play screen off and name each event. [9][10][4][house]

6. **Frequent sounds vary; priority protects the rare.** Frequent sounds get 2 to 4 variants and 60 to 130 cents of pitch spread, a 50 to 80 ms cooldown, and a voice cap (24). Rare events get high priority. Break when: the count is the signal (combo counter). Check: fire 200 events in a second; the dropped log holds only low priority. [6][house]

7. **Rank the mix by importance.** Name the loudest event; nothing else exceeds it. Rank by importance, not size. Anchors (threat cues, the player's own feedback) stay audible. Duck music 3 to 6 dB for 200 to 1000 ms under rare events, in tiers, capped near 9 dB per bus, faded not snapped. UI is the quietest tier. Break when: a finale is the new top. Check: in the densest scene name the most urgent event; fire two ducks together. [6][7][8][house]

8. **Balance by ear; numbers catch bugs.** Set music under effects, on laptop speakers and headphones. Measure only clipping, peaks and dead events. Break when: a platform sets a loudness limit. Check: a listening pass on small speakers. [6][7][house]
