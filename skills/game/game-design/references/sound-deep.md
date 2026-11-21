# Sound: detail

Read after [sound.md](sound.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Music is a composition with sections
- 2 Nothing repeats exactly for 30 to 60 seconds
- 3 Pick the adaptive method
- 4 Layers carry dynamics; quiet is planned
- 5 One distinct sound per event; sound covers the screen
- 6 Frequent sounds vary; priority protects the rare
- 7 Rank the mix by importance
- 8 Balance by ear; numbers catch bugs
- Numbers
- Sources

## 1 Music is a composition with sections

Phillips's level-music examples are built from clearly delineated song-form portions, and that is what lets them work as switchable segments [1]. A piece with no sections has nothing to switch to. Limbo's audio director avoided music that would manipulate the player and let environmental sound carry the mood [4][5]. A pitchless loop of percussion and noise reads as a drone within a minute [house].

- Good: a chord progression, a bass line that follows it, a short lead motif, and a breakdown that drops the lead.
- Bad: percussion and noise with no pitch movement, however well mixed.
- Mechanical check: the pattern file declares at least two named sections. By ear, hum the motif back after a minute.

## 2 Nothing repeats exactly for 30 to 60 seconds

Phillips reports a game that randomizes the order of more than thirty segments per level so players cannot anticipate what they hear [1]. In another, a choir layer added and removed periodically keeps the music fresh over time [3]. Predictability is the named risk of segment systems [1]. The 30 to 60 s target and variant count are ours [house].

- Good: a 4-bar bass loop under an 8-bar chord layer under a 16-bar lead; full realignment every 16 bars, a breakdown every 64.
- Bad: one 8-bar loop under a 20-minute level.
- Mechanical check: compute the least common multiple of layer lengths in seconds and compare with the target.

## 3 Pick the adaptive method

Phillips states that no single method is the best one [2]. Vertical layers add complexity without fragmenting the composition [2]; horizontal resequencing suits puzzle, exploration and stealth, or sections that signal progress [1]; seven segments plus a choir layer show the hybrid [3]. Transition points are "convenient and logical points" for a switch [1], and vertical layers "are not always meant to play simultaneously", so each must work in several configurations [2]. A success melody in its own layer blends with the current segment, and repeating it makes it memorable [3].

- Good: boss escalation through segments with hidden transitions; layer changes fade in at the next bar.
- Bad: a hard cut to a new track mid-phrase on every spawn; a chime a semitone off the bass.
- Mechanical check: every state the game can enter declares a music response (or an explicit "no change"); layer and section changes are quantised to the bar.

## 4 Layers carry dynamics; quiet is planned

Without horizontal segments, layers "do all the work to make the music feel dynamic" [2]; a spy-mission example starts sparse and gains complexity as layers join [2]. Segments that settle into silence leave the player room to think [1]. Bridgett: plan dynamics per level so not everything peaks at once;  music-free stretches relieve fatigue [8]. Andersen: lingering in loud areas causes listening fatigue [4][5]. Noise layers stay short (hats, a riser) [house].

- Good: quiet exploration, layers rising on contact, a drop-out after the fight.
- Bad: the full stack from the first second to the last.
- Mechanical check: log active layer count over a recorded session. A flat maximum for more than a couple of minutes is a flag [house].

## 5 One distinct sound per event; sound covers the screen

Overwatch's team set a goal of playing by sound and treated audio as a gameplay tool [9]. An indistinct sound cannot carry information. Enemy footsteps louder than allied ones so players can track opponents [10]. Limbo foregrounds approaching obstacles before they appear on screen to build anticipation, and plays sounds only while relevant so as not to annoy the player [4].

- Good: dash, jump and pickup are three different shapes; a rising tone as an off-screen enemy locks on.
- Bad: one generic blip for every action; damage with no sound until it lands.
- Mechanical check: every event in the game's event list maps to a sound; every telegraphed attack has a warning event. By ear, play with the screen off and name each event.

## 6 Frequent sounds vary; priority protects the rare

The mix should be invisible, steering attention toward what matters as focus shifts [6]. Numbers below are starting points tuned by ear [house]; no readable source covers variant counts.

- Good: 24 voices; big event priority 8 to 10 with one or two voices; frequent impact with 2 or 3 voices, 50 to 80 ms cooldown, three variants at plus or minus 100 cents.
- Bad: no cap, so a swarm drowns the player's own shot; one sample at fixed pitch ten times a second.
- Mechanical check: a stress test fires 200 events in one second and asserts the high-priority ones played and the dropped log contains only low-priority ones; pitch ratios in the play log vary over ten rapid firings.

## 7 Rank the mix by importance

Fable II used a troll's slam as its maximum so even a gunshot sits below it, and Bridgett advises a reference level [6]. Sounds more important to the character are more important in the mix; loudness alone should not decide it [8]. Games commonly have an anchor element that is always priority one [6]. Prototype 2 used three dialogue ducks (regular, subtle for low intensity, stronger for dense action) as snapshots, leaving asset levels alone [7]. Stacked ducking snapshots multiply and can over-attenuate, so each bus needs a maximum [8]; abrupt transitions between ducking states bumped audibly [7]. Duck depth, duration, the cap and UI levels are ours [house].

- Good: one named loudest event; tiered ducks sized to scene density; interface peak -16 to -24 dBFS, hover quietest.
- Bad: every sound normalised to full scale; three ducks at -6 stacked to -18; a hover as loud as a hit.
- Mechanical check: measure each event's peak; the loudest must be the one you named, within about 12 dB of the median event [house]. Fire two ducks together and assert bus attenuation stays under the cap. By ear, in the densest scene, name the most urgent event.

## 8 Balance by ear; numbers catch bugs

Prototype 2 found one standard loudness target too quiet for action and settled on levels by content type [7]; balance is a context judgement [6]. Measurement catches defects: sample peak above -1 dBFS, clipping, DC offset, a loop that clicks at its wrap, an event that never fires [house].

- Good: a listening pass on small speakers and headphones.
- Bad: balance set by meter alone.
- Mechanical check: the defect list above runs in `check`. Loudness and balance are not mechanical.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 30 to 60 s | nothing repeats exactly | house |
| 30+ | segments per level in one randomised game | [1] |
| 2 to 4 | variants per layer or frequent sound | house |
| 60 to 130 cents | pitch spread, frequent sounds | house |
| 50 to 80 ms | cooldown, frequent impacts | house |
| 24 | voice cap | house |
| 3 to 6 dB, 200 to 1000 ms | music duck, longer for rarer events | house |
| 6 to 9 dB | maximum stacked duck per bus | house |
| -16 to -24 dBFS | interface peak | house |
| about 12 dB | loudest event above median event | house |
| -23 / -19 / -13 | Prototype 2 voice loudness: story / action / extreme | [7] |

## Sources

1. Winifred Phillips, "Horizontal Resequencing and Dynamic Transitions for Game Music Composers", GDC 2021 write-up, Game Developer. https://www.gamedeveloper.com/audio/horizontal-resequencing-and-dynamic-transitions-for-game-music-composers-from-spyder-to-sackboy-gdc-2021-
2. Winifred Phillips, "Pure Vertical Layering for Game Music Composers", Game Developer. https://www.gamedeveloper.com/game-platforms/pure-vertical-layering-for-game-music-composers-from-spyder-to-sackboy-gdc-2021-
3. Winifred Phillips, "Hybrid Horizontal/Vertical Structure for Game Music Composers", Game Developer. https://www.gamedeveloper.com/game-platforms/hybrid-horizontal-vertical-structure-for-game-music-composers-from-spyder-to-sackboy-gdc-2021-
4. Martin Stig Andersen, Limbo interview, Designing Sound, 2011. https://designingsound.org/2011/08/01/limbo-exclusive-interview-with-martin-stig-andersen/
5. Martin Stig Andersen on Limbo sound design, Game Developer feature. https://gamedeveloper.com/audio/-i-limbo-i-sound-design-ambiguity-is-the-key-to-atmosphere
6. Rob Bridgett, "The Game Audio Mixing Revolution", Game Developer. https://www.gamedeveloper.com/audio/the-game-audio-mixing-revolution
7. Rob Bridgett, "Notes From the Mix: Prototype 2", Game Developer. https://www.gamedeveloper.com/audio/notes-from-the-mix-i-prototype-2-i-
8. Rob Bridgett, "The Future of Game Audio: Is Interactive Mixing the Key?", Game Developer. https://www.gamedeveloper.com/audio/the-future-of-game-audio---is-interactive-mixing-the-key-
9. Lawlor and Neumann, "Overwatch: The Elusive Goal: Play by Sound", GDC Vault session page (abstract only). https://gdcvault.com/play/1023010/Overwatch-The-Elusive-Goal-Play
10. Game Developer video post on the same Overwatch talk. https://www.gamedeveloper.com/audio/video-how-i-overwatch-i-was-designed-so-people-could-play-by-sound-
